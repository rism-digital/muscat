# frozen_string_literal: true

require "optparse"

def matches_tag?(marc, tag, subtag, value)
  
  marc[tag.to_s].each do |tt|
    tt[subtag.to_s].each do |t|
      if t && t.content && t.content.to_s == value.to_s
        return true
      end
    end
  end

  false
end

def split_tag_subtag(str)
  s = str.to_s.strip
  m = s.match(/\A(\d{3})([0-9a-z])\z/i) or raise ArgumentError, "Invalid tag/subtag: #{str.inspect}"
  [m[1], m[2]]
end

def value_for(record, path)
  path.to_s.split(".").reduce(record) do |obj, method|
    break nil if obj.nil?
    obj.public_send(method)
  end
end

opts = {
  columns: [],
  marc: []
}

parser = OptionParser.new do |o|
  o.banner = "Usage: ./mything [options] TYPE FILE\n\nExample:\n  ./mything --columns title,address,notes --marc 031a,031b,650a,651b Institution file.out"

  o.on("--columns LIST", "Comma-separated columns (e.g. title,address,notes)") do |v|
    opts[:columns] = v.split(",").map { _1.strip }.reject(&:empty?)
  end

  o.on("--marc LIST", "Comma-separated MARC tags/subfields (e.g. 031a,650a)") do |v|
    opts[:marc] = v.split(",").map { _1.strip }.reject(&:empty?)
  end

  o.on("--tag-filter TAG:ID", "Single tag filter (e.g. 650a:50007446). Can be given only once.") do |v|
    raise OptionParser::InvalidArgument, "--tag-filter can be specified only once" if opts[:tag_filter]

    tag, id_str = v.strip.split(":", 2)

    if tag.to_s.empty? || id_str.to_s.empty? || id_str !~ /\A\d+\z/
      raise OptionParser::InvalidArgument, "Invalid --tag-filter #{v.inspect} (expected TAG:ID, e.g. 650a:50007446)"
    end

    opts[:tag_filter] = { tag: tag, value: id_str.to_i }
  end

  o.on("-h", "--help", "Show help") do
    puts o
    exit 0
  end
end

parser.parse!(ARGV)

type = ARGV.shift
file = ARGV.shift

if type.nil? || file.nil?
  warn "Error: missing TYPE and/or FILE\n\n#{parser}"
  exit 1
end

#p opts: opts, type: type, file: file

sheet = RODF::Spreadsheet.new
table = sheet.table("#{type} export")

header = table.row
header.cell ("ID")
header.cell ("Link")
opts[:columns].each {|c| header.cell(c.to_s)}
opts[:marc].each {|c| header.cell(c.to_s)}

klass = type.to_s.classify.safe_constantize
route = klass.model_name.route_key

pb = ProgressBar.new(klass.count)
klass.find_each do |item|
  pb.increment!

  if opts.include? :tag_filter
    tag, subtag = split_tag_subtag(opts[:tag_filter][:tag])
    next if !matches_tag?(item.marc, tag, subtag, opts[:tag_filter][:value])
  end

  row = table.row

  row.cell(item.id.to_s)
  row.cell("https://muscat.rism.info/admin/#{route}/#{item.id.to_s}")

  opts[:columns].each do |c| 
    val = value_for(item, c.to_s)
    row.cell(val)
  end

  opts[:marc].each do |c| 
    tag, subtag = split_tag_subtag(c)
    
    i = []
    item.marc[tag.to_s].each do |tt|
      tt[subtag.to_s].each do |st|
        i << st.content if st && st.content
      end
    end

    row.cell(i.compact.join("\n"))
  end

end

sheet.write_to file