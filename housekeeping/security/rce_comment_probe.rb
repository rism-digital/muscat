#!/usr/bin/env ruby
# frozen_string_literal: true

# Authorized security test for Muscat's comment endpoint.
#
# Usage:
#   ruby housekeeping/security/rce_comment_probe.rb \
#     BASE_URL RESOURCE_TYPE RESOURCE_ID [LOGIN]
#
# Example:
#   ruby housekeeping/security/rce_comment_probe.rb \
#     http://localhost:3000 Source 123 editor@example.org

require "cgi"
require "io/console"
require "net/http"
require "uri"

PAYLOAD = <<~'PAYLOAD'.chomp
  hacker stuff goes here
PAYLOAD

class MuscatSecurityProbe
  REDIRECT_STATUSES = [301, 302, 303, 307, 308].freeze
  CommentResponse = Struct.new(
    :create_response,
    :final_response,
    :final_uri,
    keyword_init: true
  )

  def initialize(base_url)
    @base_uri = URI(base_url)
    unless %w[http https].include?(@base_uri.scheme) && @base_uri.host
      raise ArgumentError, "BASE_URL must be an absolute HTTP(S) URL"
    end

    @cookies = {}
  end

  def login(login, password)
    login_page = get("/admin/login")
    ensure_success!(login_page, "loading the login page")

    token = csrf_token(login_page.body)
    raise "Could not find a CSRF token on the login page" if token.nil?

    response = post_form(
      "/admin/login",
      "authenticity_token" => token,
      "user[login]" => login,
      "user[password]" => password,
      "user[remember_me]" => "0"
    )

    response, final_uri = follow_redirects(response, uri_for("/admin/login"))

    if final_uri.path == "/admin/login" || login_form?(response.body)
      raise "Login failed; check the login and password"
    end

    ensure_success!(response, "signing in")
  end

  def create_comment(resource_type, resource_id, body)
    comments_page = get("/admin/comments")
    ensure_success!(comments_page, "loading the comments page")

    token = csrf_token(comments_page.body)
    raise "Could not find a CSRF token after login" if token.nil?

    response = post_form(
      "/admin/comments",
      "authenticity_token" => token,
      "active_admin_comment[resource_type]" => resource_type,
      "active_admin_comment[resource_id]" => resource_id,
      "active_admin_comment[body]" => body,
      "commit" => "Add comment"
    )

    unless REDIRECT_STATUSES.include?(response.code.to_i)
      raise "Comment creation failed with HTTP #{response.code}"
    end

    create_response = response
    final_response, final_uri = follow_redirects(
      create_response,
      uri_for("/admin/comments")
    )
    ensure_success!(final_response, "loading the comment creation response")

    CommentResponse.new(
      create_response: create_response,
      final_response: final_response,
      final_uri: final_uri
    )
  end

  private

  def get(path)
    request(Net::HTTP::Get.new(uri_for(path)))
  end

  def post_form(path, fields)
    uri = uri_for(path)
    post_request = Net::HTTP::Post.new(uri)
    post_request.set_form_data(fields)
    request(post_request)
  end

  def request(request)
    request["Accept"] = "text/html"
    request["User-Agent"] = "Muscat-authorized-security-probe/1.0"
    request["Cookie"] = @cookies.map { |name, value| "#{name}=#{value}" }.join("; ") if @cookies.any?

    uri = request.uri
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == "https"
    http.open_timeout = 10
    http.read_timeout = 30

    response = http.request(request)
    store_cookies(response)
    response
  end

  def follow_redirects(response, current_uri, limit = 5)
    while REDIRECT_STATUSES.include?(response.code.to_i)
      raise "Too many redirects" if limit.zero?

      current_uri = same_origin_uri(response["location"], current_uri)
      response = request(Net::HTTP::Get.new(current_uri))
      limit -= 1
    end

    [response, current_uri]
  end

  def store_cookies(response)
    Array(response.get_fields("set-cookie")).each do |header|
      cookie = header.split(";", 2).first
      name, value = cookie.split("=", 2)
      @cookies[name] = value if name && value
    end
  end

  def csrf_token(body)
    tags = body.to_s.scan(/<(?:meta|input)\b[^>]*>/i)

    tags.each do |tag|
      attributes = tag.scan(/([\w-]+)\s*=\s*["']([^"']*)["']/).to_h
      next unless attributes["name"] == "csrf-token" || attributes["name"] == "authenticity_token"

      value = attributes["content"] || attributes["value"]
      return CGI.unescapeHTML(value) if value
    end

    nil
  end

  def login_form?(body)
    body.to_s.include?('name="user[password]"') ||
      body.to_s.include?("name='user[password]'")
  end

  def uri_for(path)
    uri = @base_uri.dup
    uri.path = path
    uri.query = nil
    uri.fragment = nil
    uri
  end

  def same_origin_uri(location, current_uri = @base_uri)
    raise "Redirect response did not include a Location header" if location.to_s.empty?

    uri = URI.join(current_uri.to_s, location)
    unless uri.scheme == @base_uri.scheme &&
           uri.host == @base_uri.host &&
           uri.port == @base_uri.port
      raise "Refusing cross-origin redirect to #{uri}"
    end

    uri
  end

  def ensure_success!(response, action)
    return if response.code.to_i.between?(200, 299)

    raise "HTTP #{response.code} while #{action}"
  end
end

def print_http_response(label, response, uri: nil)
  puts
  puts "=== #{label} ==="
  puts "URL: #{uri}" if uri
  puts "HTTP/#{response.http_version} #{response.code} #{response.message}"

  response.each_header do |name, value|
    next if name.downcase == "set-cookie"

    puts "#{name}: #{value}"
  end

  puts
  puts response.body.to_s
end

base_url, resource_type, resource_id, login = ARGV

if base_url.nil? || resource_type.nil? || resource_id.nil?
  warn "Usage: #{$PROGRAM_NAME} BASE_URL RESOURCE_TYPE RESOURCE_ID [LOGIN]"
  exit 2
end

if login.nil?
  print "Login: "
  STDOUT.flush
  login = STDIN.gets&.chomp
end

abort "Login cannot be empty" if login.to_s.empty?

print "Password: "
STDOUT.flush
password = STDIN.noecho(&:gets)&.chomp
puts
abort "Password cannot be empty" if password.to_s.empty?

probe = MuscatSecurityProbe.new(base_url)

begin
  probe.login(login, password)
  password.replace("\0" * password.bytesize)

  puts "Login successful."
  puts "Posting the authorized RCE_TEST comment to #{resource_type} ##{resource_id}..."

  result = probe.create_comment(resource_type, resource_id, PAYLOAD)
  puts "Comment created successfully."

  print_http_response("POST /admin/comments", result.create_response)
  print_http_response(
    "Response after redirect",
    result.final_response,
    uri: result.final_uri
  )

  puts "Review the application logs for unexpected command execution or deserialization errors."
rescue StandardError => error
  warn "Probe failed: #{error.message}"
  exit 1
ensure
  password&.replace("\0" * password.bytesize)
end
