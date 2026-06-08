# frozen_string_literal: true

# A real example:
# rails r housekeeping/correct/131_extract_fields.rb --columns wf_stage,record_type --marc 100a,100d,100j,852a,852e,852b,852z,852c,852d,240a,240o,240k,240r,240m,520a,561a,700a,700d,700j,7004,260c,300a,590a --export-sigla CH-ZUkao CH.ods

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
  o.banner = "Usage: [options] FILE\n\nExamples:\n  --model Institution --columns title,address,notes --marc 031a,031b,650a,651b file.out\n  ./mything --export-sigla D-B --columns title --marc 031a,852a file.out"

  o.on("--columns LIST", "Comma-separated columns (e.g. title,address,notes)") do |v|
    opts[:columns] = v.split(",").map { _1.strip }.reject(&:empty?)
  end

  o.on("--marc LIST", "Comma-separated MARC tags/subfields (e.g. 031a,650a)") do |v|
    opts[:marc] = v.split(",").map { _1.strip }.reject(&:empty?)
  end

  o.on("--model NAME", "Model name to export (e.g. Institution, Source)") do |v|
    opts[:model] = v.strip
  end

  o.on("--export-sigla SIGLUM", "Export sources and holdings referring to the institution siglum") do |v|
    opts[:export_sigla] = v.strip
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

file = ARGV.shift
mode_count = [opts[:model], opts[:export_sigla]].compact.count

if mode_count != 1
  warn "Error: specify exactly one of --model or --export-sigla\n\n#{parser}"
  exit 1
end

if file.nil?
  warn "Error: missing FILE\n\n#{parser}"
  exit 1
end

if ARGV.any?
  warn "Error: unexpected arguments: #{ARGV.join(", ")}\n\n#{parser}"
  exit 1
end

if opts[:model]
  klass = opts[:model].to_s.classify.safe_constantize

  if klass.nil?
    warn "Error: unknown model #{opts[:model].inspect}"
    exit 1
  end

  route = klass.model_name.route_key
  export_name = opts[:model]
  item_count = klass.count
  items = klass.find_each
else
  institutions = Institution.where(siglum: opts[:export_sigla]).to_a

  if institutions.empty?
    warn "Error: no institution found with siglum #{opts[:export_sigla].inspect}"
    exit 1
  end

  route = Source.model_name.route_key
  export_name = opts[:export_sigla]
  items = institutions.flat_map do |institution|
    institution.referring_sources.to_a + institution.referring_holdings.to_a
  end
  item_count = items.count
end

sheet = RODF::Spreadsheet.new
table = sheet.table("#{export_name} export")

header = table.row
header.cell ("ID")
header.cell ("Link")
opts[:columns].each {|c| header.cell(c.to_s)}
opts[:marc].each {|c| header.cell(c.to_s)}

pb = ProgressBar.new(item_count)
items.each do |export_item|
  pb.increment!

  # When exporting holdings, used with --ecport-sigla
  if opts[:export_sigla] && export_item.is_a?(Holding)
    item = export_item.source
  else
    item = export_item
  end

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
    
    # We need to pull the 852, if specified by the user, from the holding
    # Maybe other items too?
    if opts[:export_sigla] && tag == "852" && export_item.is_a?(Holding)
      marc = export_item.marc
    else
      marc = item.marc
    end

    i = []
    marc[tag.to_s].each do |tt|
      tt[subtag.to_s].each do |st|
        i << st.content if st && st.content
      end
    end

    row.cell(i.compact.join("\n"))
  end

end

sheet.write_to file
