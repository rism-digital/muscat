require "csv"
require "json"

USAGE = <<~HELP
  Compare legacy PSMD manuscript tags with current Muscat source tags.

  Usage:
    rails runner housekeeping/psmd/compare_current_tags.rb LEGACY_TAGS.csv OUTPUT.csv

  LEGACY_TAGS.csv is produced by export_legacy_tags.rb. Its first columns are
  Manuscript_id, ModernSourceId, Tags, and LegacyStatus. A header is optional.
  Tag columns in the output are JSON arrays of unique, sorted MARC field codes.
HELP

INPUT_HEADERS = %w[Manuscript_id ModernSourceId Tags].freeze
SKIPPED_TAGS = %w[000 001 003 005 007 008 033 035 040].freeze
OUTPUT_HEADERS = [
  "Manuscript_id",
  "ModernSourceId",
  "TagsInBoth",
  "TagsOnlyInOld",
  "TagsOnlyInNew",
  "LegacyStatus",
  "CurrentStatus"
].freeze

def marc_tags(record)
  # false keeps this read-only comparison from resolving external MARC links.
  record.marc.all_tags(false).map { |node| node.tag.to_s }
    .reject { |tag| tag.empty? || SKIPPED_TAGS.include?(tag) }
    .uniq.sort
end

def parse_legacy_tags(value, line_number)
  tags = JSON.parse(value.to_s)
  unless tags.is_a?(Array) && tags.all? { |tag| tag.is_a?(String) && tag =~ /\A\d{3}\z/ }
    raise JSON::ParserError, "expected a JSON array of three-digit tag strings"
  end
  tags.reject { |tag| SKIPPED_TAGS.include?(tag) }.uniq.sort
rescue JSON::ParserError => error
  abort "Invalid Tags value on input line #{line_number}: #{error.message}"
end

def validate_input!(input_path, output_path)
  abort USAGE unless input_path && output_path && ARGV.empty?
  abort "Input file not found: #{input_path}" unless File.file?(input_path)
  abort "Input and output files must be different." if File.expand_path(input_path) == File.expand_path(output_path)
end

def each_input_row(input_path)
  File.open(input_path, "r:bom|utf-8") do |file|
    CSV.new(file).each_with_index do |row, index|
      next if index == 0 && row[0, 3] == INPUT_HEADERS
      yield row, index + 1
    end
  end
end

input_path, output_path = ARGV.shift(2)
validate_input!(input_path, output_path)

counts = Hash.new(0)

CSV.open(output_path, "wb", headers: OUTPUT_HEADERS, write_headers: true) do |output|
  each_input_row(input_path) do |row, line_number|
    manuscript_id = row[0].to_s.strip
    modern_source_id = row[1].to_s.strip
    old_tags = parse_legacy_tags(row[2], line_number)
    legacy_status = row[3].to_s.strip
    legacy_status = "OK" if legacy_status.empty?
    current_status = "OK"
    new_tags = []

    if modern_source_id.empty?
      current_status = "INVALID MODERN SOURCE ID (input line #{line_number})"
    else
      source = Source.find_by_id(modern_source_id)
      if source.nil?
        current_status = "SOURCE NOT FOUND"
      else
        new_tags = marc_tags(source)
        current_status = "MARC EMPTY" if new_tags.empty?
      end
    end

    tags_in_both = old_tags & new_tags
    tags_only_in_old = old_tags - new_tags
    tags_only_in_new = new_tags - old_tags

    counts[current_status] += 1
    output << [
      manuscript_id,
      modern_source_id,
      JSON.generate(tags_in_both),
      JSON.generate(tags_only_in_old),
      JSON.generate(tags_only_in_new),
      legacy_status,
      current_status
    ]
  end
end

row_count = counts.values.inject(0, :+)
warn "Wrote #{row_count} rows to #{output_path} (#{counts.sort.map { |status, count| "#{status}: #{count}" }.join(', ')})"
