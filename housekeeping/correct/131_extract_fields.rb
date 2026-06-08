# frozen_string_literal: true

# A real example:
# rails r housekeeping/correct/131_extract_fields.rb --columns wf_stage,record_type --marc 100a,100d,100j,852a,852e,852b,852z,852c,852d,240a,240o,240k,240r,240m,520a,561a,700a,700d,700j,7004,260c,300a,590a --export-sigla CH-ZUkao CH.ods
# Compact version
# rails r housekeeping/correct/131_extract_fields.rb --columns wf_stage,record_type --marc 100,852,240,520a,561a,700,260c,300a,590a --export-sigla CH-ZUkao CH-ZUkao.ods
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

def split_tag_subtag(str, require_subtag: false)
  s = str.to_s.strip
  m = s.match(/\A(\d{3})([0-9a-z])?\z/i) or raise ArgumentError, "Invalid tag/subtag: #{str.inspect}"

  if require_subtag && m[2].nil?
    raise ArgumentError, "Invalid tag/subtag: #{str.inspect}"
  end

  [m[1], m[2]]
end

def configured_subtags_for(config, tag)
  subtags = []
  Array(config).compact.each do |single_config|
    next if !single_config.has_tag?(tag.to_s) || single_config.is_tagless?(tag.to_s)

    single_config.each_subtag(tag.to_s) do |subtag|
      subtag_name = subtag[0].to_s
      subtags << subtag_name if !subtags.include?(subtag_name)
    end
  end

  subtags
end

def expand_marc_fields(fields, default_config, config_by_tag = {})
  fields.flat_map do |field|
    tag, subtag = split_tag_subtag(field)

    if subtag
      [{ header: "#{tag}#{subtag}", tag: tag, subtag: subtag }]
    else
      config = config_by_tag.fetch(tag, default_config)
      configs = Array(config).compact

      if configs.any? { |single_config| single_config.has_tag?(tag) && single_config.is_tagless?(tag) }
        [{ header: tag, tag: tag, subtag: nil }]
      else
        configured_subtags_for(config, tag).map do |configured_subtag|
          { header: "#{tag}#{configured_subtag}", tag: tag, subtag: configured_subtag }
        end
      end
    end
  end
end

def route_key_for(model)
  model_class = model.is_a?(Class) ? model : model.to_s.safe_constantize
  return model_class.model_name.route_key if model_class

  model.to_s.underscore.pluralize
end

def record_url(model, id, base_url)
  "#{base_url}/#{route_key_for(model)}/#{id}"
end

def linked_master_subtag?(marc, tag, subtag)
  return false if subtag.nil?

  config = marc.instance_variable_get(:@marc_configuration)
  return false if config.nil? || !config.has_tag?(tag.to_s)
  return false if config.get_master(tag.to_s).to_s != subtag.to_s

  foreign_class = config.get_subtag_attribute(tag.to_s, subtag.to_s, :foreign_class)
  foreign_class && !foreign_class.to_s.start_with?("^")
end

def linked_master_url(marc, tag, subtag, id, base_url)
  config = marc.instance_variable_get(:@marc_configuration)
  foreign_class = config.get_subtag_attribute(tag.to_s, subtag.to_s, :foreign_class)
  record_url(foreign_class, id, base_url)
end

def marc_value_for_subtag(marc, tag, subtag, st, base_url)
  return nil if st.nil? || st.content.nil?

  if linked_master_subtag?(marc, tag, subtag)
    id = st.content.to_s.strip
    id.empty? ? st.content : linked_master_url(marc, tag, subtag, id, base_url)
  else
    st.content
  end
end

def marc_values_for(marc, tag, subtag, base_url)
  values = []

  marc[tag.to_s].each do |tt|
    if subtag
      tt[subtag.to_s].each do |st|
        values << marc_value_for_subtag(marc, tag, subtag, st, base_url)
      end
    elsif tt.has_children?
      tt.children.each do |st|
        values << marc_value_for_subtag(marc, tag, st.tag, st, base_url)
      end
    elsif tt.content
      values << tt.content
    end
  end

  values.compact
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

  o.on("--marc LIST", "Comma-separated MARC tags/subfields; bare tags expand to configured subfields (e.g. 031a,650a,700)") do |v|
    opts[:marc] = v.split(",").map { _1.strip }.reject(&:empty?)
  end

  o.on("--model NAME", "Model name to export (e.g. Institution, Source)") do |v|
    opts[:model] = v.strip
  end

  o.on("--export-sigla SIGLUM", "Export sources and holdings referring to the institution siglum") do |v|
    opts[:export_sigla] = v.strip
  end

  o.on("--rism-online-links", "Use https://rism.online links instead of https://muscat.rism.info/admin") do
    opts[:rism_online_links] = true
  end

  o.on("--tag-filter TAG:ID", "Single tag filter (e.g. 650a:50007446). Can be given only once.") do |v|
    raise OptionParser::InvalidArgument, "--tag-filter can be specified only once" if opts[:tag_filter]

    tag, id_str = v.strip.split(":", 2)

    if tag.to_s.empty? || id_str.to_s.empty? || id_str !~ /\A\d+\z/
      raise OptionParser::InvalidArgument, "Invalid --tag-filter #{v.inspect} (expected TAG:ID, e.g. 650a:50007446)"
    end

    begin
      split_tag_subtag(tag, require_subtag: true)
    rescue ArgumentError
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

base_url = opts[:rism_online_links] ? "https://rism.online" : "https://muscat.rism.info/admin"

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
  default_marc_config = MarcConfigCache.get_configuration(klass.name.underscore)
  marc_config_by_tag = {}
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
  source_marc_config = MarcConfigCache.get_configuration("source")
  holding_marc_config = MarcConfigCache.get_configuration("holding")
  default_marc_config = source_marc_config
  marc_config_by_tag = { "852" => [source_marc_config, holding_marc_config] }
end

marc_fields = expand_marc_fields(opts[:marc], default_marc_config, marc_config_by_tag)

sheet = RODF::Spreadsheet.new
table = sheet.table("#{export_name} export")

header = table.row
header.cell ("ID")
header.cell ("Link")
opts[:columns].each {|c| header.cell(c.to_s)}
marc_fields.each {|c| header.cell(c[:header])}

pb = ProgressBar.new(item_count)
items.each do |export_item|
  pb.increment!

  # When exporting holdings, used with --export-sigla.
  if opts[:export_sigla] && export_item.is_a?(Holding)
    item = export_item.source
  else
    item = export_item
  end

  if opts.include? :tag_filter
    tag, subtag = split_tag_subtag(opts[:tag_filter][:tag], require_subtag: true)
    next if !matches_tag?(item.marc, tag, subtag, opts[:tag_filter][:value])
  end

  row = table.row

  row.cell(item.id.to_s)
  row.cell("#{base_url}/#{route}/#{item.id.to_s}")

  opts[:columns].each do |c| 
    val = value_for(item, c.to_s)
    row.cell(val)
  end

  marc_fields.each do |field| 
    tag = field[:tag]
    subtag = field[:subtag]

    # We need to pull the 852, if specified by the user, from the holding
    # Maybe other items too?
    if opts[:export_sigla] && tag == "852" && export_item.is_a?(Holding)
      marc = export_item.marc
    else
      marc = item.marc
    end

    row.cell(marc_values_for(marc, tag, subtag, base_url).join("\n"))
  end

end

sheet.write_to file
