# Usage: bin/rails r housekeeping/correct/156_scan_protypen_codes.rb Source

require_relative "../../lib/protypenliste"
require "optparse"

EXCLUDED_PROPERTIES = %w[shelf_mark full_name std_title wikidata_id identifiers].freeze
EXCLUDED_MARC_TAGS = %w[852 856 024 690 691 931 300 500 035 588 591 700 599 551 667].freeze
EXCLUDED_MARC_SUBFIELDS = {
  "031" => %w[p].freeze,
  "240" => %w[n].freeze
}.freeze

def each_marc_node(node, path = [], &block)
  current_path = path + [node.tag].compact
  yield node, current_path
  node.children.each { |child| each_marc_node(child, current_path, &block) }
end

def print_protypen_matches(record_id, location, text, code_pattern)
  counts = Hash.new(0)
  text.scan(code_pattern) { |prefix, code| counts[[prefix, code]] += 1 }

  counts.each do |(prefix, code), count|
    puts [
      record_id,
      location,
      "#{prefix}#{code}",
      Protypenliste::CODE_TO_CHARACTER.fetch(code),
      count,
      text.inspect
    ].join("\t")
  end

  counts.values.sum
end

marker_mode = :both
marker_option_used = false
options = OptionParser.new do |parser|
  parser.banner = "Usage: bin/rails r housekeeping/correct/156_scan_protypen_codes.rb MODEL [--with-star | --without-star]"
  parser.on("--with-star", "Match only codes prefixed by * or \\*") do
    raise OptionParser::InvalidArgument, "choose only one marker option" if marker_option_used

    marker_mode = :with_star
    marker_option_used = true
  end
  parser.on("--without-star", "Match only unprefixed codes") do
    raise OptionParser::InvalidArgument, "choose only one marker option" if marker_option_used

    marker_mode = :without_star
    marker_option_used = true
  end
end

begin
  options.parse!(ARGV)
rescue OptionParser::ParseError => error
  abort "#{error.message}\n#{options}"
end

model_name = ARGV.shift
if model_name.nil? || model_name.empty? || ARGV.any?
  abort "#{options}"
end

model = model_name.classify.safe_constantize
unless model.is_a?(Class) && model <= ActiveRecord::Base && !model.abstract_class?
  abort "Unknown Active Record model: #{model_name}"
end

# Letter-plus-two-digit codes substitute for letters. The *NNN entries in the
# reference are symbol codes, not the letter codes this scanner is looking for.
letter_codes = Protypenliste::CODE_TO_CHARACTER.keys.grep(/\A[A-Za-z][0-9]{2}\z/)
abort "No letter Protypen codes are configured." if letter_codes.empty?

# Match codes inside words, optionally preceded by * or by an escaped asterisk.
codes_pattern = Regexp.union(letter_codes)
code_pattern = case marker_mode
               when :with_star then /((?:\\?\*))(#{codes_pattern})/
               when :without_star then /()(#{codes_pattern})/
               else /((?:\\?\*)?)(#{codes_pattern})/
               end
marc_model = model.columns_hash.key?("marc_source") && model.method_defined?(:marc)
searchable_columns = model.columns.reject do |column|
  column.type == :binary ||
    EXCLUDED_PROPERTIES.include?(column.name) ||
    (marc_model && column.name == "marc_source")
end

puts "model\t#{model.name}"
puts "record_id\tcolumn_or_tag\tmatched_code\tcharacter\tcount\tfull_string_escaped"

records_scanned = 0
records_with_matches = 0
fields_with_matches = 0
occurrences = 0

model.find_each do |record|
  records_scanned += 1
  record_matched = false

  searchable_columns.each do |column|
    value = record.read_attribute(column.name)
    text = case value
           when String then value
           when Hash, Array then value.to_json
           else next
           end
    next unless text.valid_encoding?

    match_count = print_protypen_matches(record.id, column.name, text, code_pattern)
    next if match_count.zero?

    record_matched = true
    fields_with_matches += 1
    occurrences += match_count
  end

  if marc_model
    begin
      record.marc.all_tags(false).each do |field|
        # The leader (000) is record metadata; its standard value contains
        # sequences such as "a22" that are not text substitutions.
        next if field.tag == "000" || EXCLUDED_MARC_TAGS.include?(field.tag)

        each_marc_node(field) do |node, path|
          next unless node.content.is_a?(String) && node.content.valid_encoding?
          next if EXCLUDED_MARC_SUBFIELDS.fetch(path.first, []).include?(path[1])

          location = "MARC #{path.first}#{path.drop(1).map { |subtag| " $#{subtag}" }.join}"
          match_count = print_protypen_matches(record.id, location, node.content, code_pattern)
          next if match_count.zero?

          record_matched = true
          fields_with_matches += 1
          occurrences += match_count
        end
      end
    rescue StandardError => error
      warn "Could not parse MARC data for #{model.name} #{record.id}: #{error.class}: #{error.message}"
    end
  end

  records_with_matches += 1 if record_matched
end

puts "records_scanned\t#{records_scanned}"
puts "records_with_matches\t#{records_with_matches}"
puts "fields_with_matches\t#{fields_with_matches}"
puts "occurrences\t#{occurrences}"
