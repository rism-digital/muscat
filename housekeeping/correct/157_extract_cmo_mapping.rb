require "csv"

# Export the mapping between CMO identifiers (024 $a, with 024 $2 = CMO)
# and Muscat person records. Pass an optional output path; otherwise CSV goes
# to stdout and can be redirected to a file.
#
# Usage:
#   bin/rails runner housekeeping/correct/157_extract_cmo_mapping.rb [output.csv]

output_path = ARGV.shift

if ARGV.any?
  abort "Usage: bin/rails runner housekeeping/correct/157_extract_cmo_mapping.rb [output.csv]"
end

headers = %w[person_name cmo_id muscat_id]
write_rows = lambda do |csv|
  Person.find_each do |person|
    person.marc["024"].each do |field|
      source_codes = field["2"].to_a.map { |subfield| subfield.content.to_s.strip }
      next unless source_codes.include?("CMO")

      field["a"].to_a.each do |subfield|
        cmo_id = subfield.content.to_s.strip
        next if cmo_id.empty?

        csv << [person.full_name, cmo_id, person.id]
      end
    end
  end
end

if output_path
  CSV.open(output_path, "wb", headers: headers, write_headers: true) do |csv|
    write_rows.call(csv)
  end
else
  csv = CSV.new($stdout, headers: headers, write_headers: true)
  write_rows.call(csv)
end
