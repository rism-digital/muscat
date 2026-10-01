require "csv"
require "json"

USAGE = <<~HELP
  Export the MARC tags for PSMD manuscripts from the legacy Muscat database.

  Usage:
    rails runner housekeeping/psmd/export_legacy_tags.rb INPUT.csv OUTPUT.csv

  The first two columns of INPUT.csv are Manuscript_id and ModernSourceId.
  A header row is optional.

  OUTPUT.csv contains the two IDs, a JSON array of unique MARC tags, and a
  status column. The output is the input for compare_current_tags.rb.
HELP

INPUT_HEADERS = %w[Manuscript_id ModernSourceId].freeze
OUTPUT_HEADERS = INPUT_HEADERS + ["Tags", "LegacyStatus"].freeze

def marc_tags(record)
  marc = record.marc
  tags = []

  # The legacy Marc has no all_tags method. Load without resolving external
  # links, then ask it to yield every distinct top-level tag. Passing false to
  # each_data_tags_present includes control fields such as 001.
  marc.load_source(false)
  marc.each_data_tags_present(false) { |tag| tags << tag.to_s }

  tags.reject(&:empty?).uniq.sort
end

def validate_input!(input_path, output_path)
  abort USAGE unless input_path && output_path && ARGV.empty?
  abort "Input file not found: #{input_path}" unless File.file?(input_path)
  abort "Input and output files must be different." if File.expand_path(input_path) == File.expand_path(output_path)
end

def each_input_row(input_path)
  File.open(input_path, "r:bom|utf-8") do |file|
    CSV.new(file).each_with_index do |row, index|
      next if index == 0 && row[0, 2] == INPUT_HEADERS
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
    status = "OK"
    tags = []

    if manuscript_id.empty? || modern_source_id.empty?
      status = "INVALID IDS (input line #{line_number})"
    else
      manuscript = Manuscript.find_by_id(manuscript_id)
      if manuscript.nil?
        status = "MANUSCRIPT NOT FOUND"
      else
        tags = marc_tags(manuscript)
        if tags.empty?
          status = "MARC EMPTY"
        end
      end
    end

    counts[status] += 1
    output << [manuscript_id, modern_source_id, JSON.generate(tags), status]
  end
end

row_count = counts.values.inject(0, :+)
warn "Wrote #{row_count} rows to #{output_path} (#{counts.sort.map { |status, count| "#{status}: #{count}" }.join(', ')})"
