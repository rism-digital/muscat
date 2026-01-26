# frozen_string_literal: true

require "optparse"

options = { url: nil }

parser = OptionParser.new do |opts|
  opts.banner = "Usage: #{File.basename($PROGRAM_NAME)} [options] Folder Institution"
  opts.on("-u", "--url URL", "Optional URL") { |u| options[:url] = u }
  opts.on("-h", "--help", "Show help") do
    puts opts
    exit 0
  end
end

begin
  parser.parse!
rescue OptionParser::InvalidOption => e
  warn e.message
  warn parser
  exit 1
end

if ARGV.length != 2
  warn parser
  exit 1
end

folder = ARGV.shift
institution = ARGV.shift
url = options[:url]

f = Folder.find(folder)
i = Institution.find(institution)

if f.folder_type != "Source"
  puts "Works only for sources for now"
  exit
end

f.folder_items.each do |fi|
  
  if !fi.item.is_a? Source
    puts "Skip #{!fi.item.id}, is not a source"
  end

  s = fi.item

  skip = s.marc["910"].any? do |t|
    t["0"].any? { |tt| tt&.content.to_s == i.id.to_s }
  end

  if skip
    puts "SKIP item #{s.id} not adding duplicate #{i.id}"
    next
  end

  s.marc.add_tag_with_subfields("910", "0": i.id.to_s, u: url)
  s.marc.import
  s.save

end