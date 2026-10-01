# Run with:
#   bin/rails runner housekeeping/correct/518_fix_report.rb [518_wrong.csv]
#
# Writes TSV to stdout. Matching records emit one row per matching 518$a.
# Unmatched records emit their current 518$a values in one field, separated by " || ".

require "csv"

input_path = ARGV.fetch(0, Rails.root.join("518_wrong.csv").to_s)
abort "Input file not found: #{input_path}" unless File.file?(input_path)

def write_tsv(fields)
  STDOUT.write(CSV.generate_line(fields, col_sep: "\t", row_sep: "\n"))
end

CSV.foreach(input_path, encoding: "bom|utf-8").with_index(1) do |row, _line_number|
  next if row.nil? || row.empty?

  muscat_id = row[0].to_s.strip
  #next unless muscat_id.match?(/\A\d+\z/)

  source = Source.find_by(id: muscat_id)
  if !source
    write_tsv([muscat_id, "DELETED"])
    next
  end

  input_columns = row.first(3).map { |value| value.to_s }
  input_columns << "" while input_columns.length < 3
  search_value = input_columns[2].strip

  current_values = source.marc.by_tags("518").flat_map do |field|
    field.fetch_all_by_tag("a").filter_map do |subfield|
      subfield&.content
    end
  end

  matches = if search_value.empty?
    []
  else
    current_values.select { |value| value.include?(search_value) }
  end

  if matches.any?
    date = row[3].to_s.strip
    date = "" if date.casecmp("e").zero?
    place = row[4].to_s.strip
    new_value = "Performance date: " + [date, place].reject(&:empty?).join(" ")

    matches.each do |value|
      write_tsv(input_columns + [value, new_value])
    end
  else
   # existing_value = current_values.join(" || ")
    write_tsv(input_columns + ["Maybe corrected in muscat"])
  end
end
