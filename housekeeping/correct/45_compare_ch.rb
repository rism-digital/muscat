require 'net/http'

URL = "http://dev.muscat-project.org/catalog/"

Source.limit(300).each do |orig_source|

    m = Net::HTTP.get(URI(URL + "#{orig_source.id}.txt"))

    marc = MarcSource.new(m)
    marc.load_source(false)

    first = "n.a."
    second = "n.a."

    marc.each_by_tag("245") do |t|
        first = t.to_s.force_encoding("UTF-8")
    end

    orig_source.marc.each_by_tag("245") do |t|
        second =  t.to_s.force_encoding("UTF-8")
    end

    puts "#{orig_source.id}\t#{first.to_s.strip}\t#{second.to_s.strip}"
end