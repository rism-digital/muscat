require "net/http"
require "uri"
require "openssl"

module UrlChecker
  Result = Struct.new(
    :input_url, :final_url, :status, :category, :message, :redirect_chain,
    keyword_init: true
  )

  def self.check(url, max_redirects: 5, timeout: 5)
    input = url
    redirect_chain = []

    uri = URI.parse(url)
    unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
      return Result.new(input_url: input, category: :invalid_url, message: "Unsupported or missing scheme")
    end

    redirects = 0

    loop do
      resp = request(uri, timeout: timeout)

      # HEAD not allowed? try GET once (still minimal: no body needed, but Net::HTTP reads headers first)
      if resp.is_a?(Net::HTTPMethodNotAllowed)
        resp = request(uri, timeout: timeout, method: :get)
      end

      status = resp.code.to_i

      case status
      when 200..299
        return Result.new(
          input_url: input,
          final_url: uri.to_s,
          status: status,
          category: :ok,
          message: resp.message,
          redirect_chain: redirect_chain
        )
      when 300..399
        location = resp["location"]
        return Result.new(
          input_url: input,
          final_url: uri.to_s,
          status: status,
          category: :redirect_no_location,
          message: "Redirect without Location header",
          redirect_chain: redirect_chain
        ) if location.nil? || location.strip.empty?

        redirect_chain << { from: uri.to_s, status: status, location: location }

        redirects += 1
        return Result.new(
          input_url: input,
          final_url: uri.to_s,
          status: status,
          category: :too_many_redirects,
          message: "Exceeded max_redirects=#{max_redirects}",
          redirect_chain: redirect_chain
        ) if redirects > max_redirects

        uri = uri.merge(URI::DEFAULT_PARSER.escape(location)) # handles relative redirects
        next
      when 400..499
        return Result.new(
          input_url: input,
          final_url: uri.to_s,
          status: status,
          category: :client_error,
          message: resp.message,
          redirect_chain: redirect_chain
        )
      when 500..599
        return Result.new(
          input_url: input,
          final_url: uri.to_s,
          status: status,
          category: :server_error,
          message: resp.message,
          redirect_chain: redirect_chain
        )
      else
        return Result.new(
          input_url: input,
          final_url: uri.to_s,
          status: status,
          category: :unknown_status,
          message: resp.message,
          redirect_chain: redirect_chain
        )
      end
    end
  rescue URI::InvalidURIError => e
    Result.new(input_url: input, category: :invalid_url, message: e.message, redirect_chain: [])
  rescue SocketError => e
    Result.new(input_url: input, category: :dns_error, message: e.message, redirect_chain: [])
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    Result.new(input_url: input, category: :timeout, message: e.class.name, redirect_chain: [])
  rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH => e
    Result.new(input_url: input, category: :connection_error, message: e.class.name, redirect_chain: [])
  rescue OpenSSL::SSL::SSLError => e
    Result.new(input_url: input, category: :ssl_error, message: e.message, redirect_chain: [])
  rescue StandardError => e
    Result.new(input_url: input, category: :error, message: "#{e.class}: #{e.message}", redirect_chain: [])
  end

  def self.request(uri, timeout:, method: :head)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = timeout
    http.read_timeout = timeout
    http.write_timeout = timeout if http.respond_to?(:write_timeout)

    # If you need to accept self-signed certs (usually don't), you can change this:
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER if http.use_ssl?

    klass = (method == :get) ? Net::HTTP::Get : Net::HTTP::Head
    req = klass.new(uri.request_uri, { "User-Agent" => "UrlChecker/1.0" })

    http.start { |h| h.request(req) }
  end
end

=begin
File.open("URLs.tsv", "w") do |file|

pb = ProgressBar.new(Source.count)
Source.find_each do |s|

  s.marc.load_source false
  s.marc["856"].each do |tt|
    tt["u"].each do |ttt|
      if ttt && ttt.content
        r = UrlChecker.check(ttt.content)
        file.write [s.id, ttt.content, r[:category], r[:message], r[:status], "\n"].join("\t")
      end
    end
  end

  pb.increment!

end
end
=end

mutex = Mutex.new

File.open("URLs.tsv", "w") do |file|

  check_items = ->(batch) do
    payload = ""
    batch.each do |s|
      next if !s.marc_source.include?("=856")
      s.marc.load_source false
      s.marc["856"].each do |tt|
        tt["u"].each do |ttt|
          if ttt && ttt.content
            r = UrlChecker.check(ttt.content)
            payload += [s.id, ttt.content, r[:category], r[:message], r[:status], "\n"].join("\t")
          end
        end
      end
    end
    mutex.synchronize { file.write(payload) }
  end

  results = Parallelizator.new( Source, check_items, backend: :threads, mode: :batch, batch_size: 100, jobs: 32, where_sql: "marc_source like '%=856%'").run
  file.flush
  puts Parallelizator.summarize(results)
end
