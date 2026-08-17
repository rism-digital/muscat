require "csv"

USAGE = <<~'HELP'
  Create holdings from a delimited file and attach them to existing sources.

  Usage:
    rails runner housekeeping/correct/150_create_holdings_from_list.rb FILE

  The first column contains the source ID. Every following non-empty column
  header must identify a MARC tag and subfield, for example:

    muscat_id  852$a  852$q  852$c  856$u  856$z  856$x  691$a  691$n  500$a  599$a

  Comma-, semicolon-, and tab-separated files are accepted. Fields belonging
  to the same MARC tag are created as subfields of one tag. A row is skipped
  and reported as ALREADY HAS HOLDING when the source already has a holding
  with the siglum supplied in 852$a.

  Output is TSV and can be redirected to a report file.
HELP

FIELD_HEADER = /\A(\d{3})\$?([0-9A-Za-z])\z/

def output_tsv(*values)
  puts CSV.generate_line(values, col_sep: "\t")
end

def column_separator(filename)
  header = File.open(filename, "r:bom|utf-8", &:gets).to_s
  ["\t", ",", ";"].max_by { |separator| header.count(separator) }
end

def template_name(source)
  case source.get_record_type
  when :libretto_edition
    "libretto_holding_default.marc"
  when :theoretica_edition
    "treatise_holding_default.marc"
  else
    "default.marc"
  end
end

def fields_from(row)
  row.each_with_object({}) do |(header, value), fields|
    next if header.nil? || header.strip.empty?

    match = FIELD_HEADER.match(header.strip)
    next unless match

    content = value&.strip
    next if content.nil? || content.empty?

    tag, subfield = match.captures
    fields[tag] ||= {}
    fields[tag][subfield] = content
  end
end

filename = ARGV.shift

if filename.nil? || ARGV.any? || !File.file?(filename)
  warn USAGE
  exit 1
end

separator = column_separator(filename)
headers = CSV.open(filename, "r:bom|utf-8", headers: true, col_sep: separator) do |table|
  table.first&.headers
end

if headers.nil?
  warn "The input file is empty."
  exit 1
end

marc_headers = headers.drop(1).compact.reject { |header| header.strip.empty? }
invalid_headers = marc_headers.reject { |header| FIELD_HEADER.match?(header.strip) }

unless invalid_headers.empty?
  warn "Invalid MARC field headers: #{invalid_headers.join(', ')}"
  exit 1
end

unless marc_headers.any? { |header| header.strip.match?(/\A852\$?a\z/i) }
  warn 'The input must have an 852$a column so existing holdings can be detected.'
  exit 1
end

counts = Hash.new(0)
output_tsv("source_id", "siglum", "status", "details")

# Reopen after reading the first row while validating the headers.
CSV.foreach(filename, headers: true, col_sep: separator, encoding: "bom|utf-8") do |row|
  source_id = row[0]&.strip
  fields = fields_from(row)
  siglum = fields.dig("852", "a")

  if source_id.to_s.empty? || siglum.to_s.empty?
    counts["INVALID ROW"] += 1
    output_tsv(source_id, siglum, "INVALID ROW", "source ID and 852$a are required")
    next
  end

  source = Source.find_by(id: source_id)
  unless source
    counts["SOURCE NOT FOUND"] += 1
    output_tsv(source_id, siglum, "SOURCE NOT FOUND", nil)
    next
  end

  existing_ids = source.holdings.where(lib_siglum: siglum).pluck(:id)
  if existing_ids.any?
    counts["ALREADY HAS HOLDING"] += 1
    output_tsv(source_id, siglum, "ALREADY HAS HOLDING", existing_ids.join(","))
    next
  end

  begin
    holding = nil

    Holding.transaction do
      profile = ConfigFilePath.get_marc_editor_profile_path(
        Rails.root.join("config", "marc", RISM::MARC, "holding", template_name(source)).to_s
      )
      marc = MarcHolding.new(File.read(profile))
      marc.load_source(false)
      marc.each_by_tag("852") { |tag| tag.destroy_yourself }

      fields.each do |tag, subfields|
        marc.add_tag_with_subfields(tag, subfields)
      end

      # Resolve foreign fields such as the institution in 852 and the
      # publication in 691 before the holding relations are scaffolded.
      marc.suppress_scaffold_links
      marc.import

      holding = Holding.new(
        source: source,
        wf_owner: source.wf_owner,
        wf_stage: :published,
        wf_audit: :imported
      )
      holding.marc = marc
      holding.suppress_reindex
      holding.save!
    end

    counts["CREATED"] += 1
    output_tsv(source_id, siglum, "CREATED", holding.id)
  rescue StandardError => error
    counts["ERROR"] += 1
    output_tsv(source_id, siglum, "ERROR", error.message)
  end
end

warn counts.sort.map { |status, count| "#{status}: #{count}" }.join(", ")
