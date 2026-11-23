# Run with:
#   bin/rails runner housekeeping/correct/160_add_751_from_csv.rb [path/to/file.csv]

require "csv"

input_path = ARGV.fetch(0, Rails.root.join("2026-11-260a-Export-Ziele.csv").to_s)
abort "Input file not found: #{input_path}" unless File.file?(input_path)

rows = CSV.read(input_path, headers: true, encoding: "bom|utf-8")
required_headers = %w[rism_quell_id rism_place_id ort_name]
missing_headers = required_headers - rows.headers
abort "Missing CSV headers: #{missing_headers.join(', ')}" if missing_headers.any?

#Source.transaction do
  rows.each_with_index do |row, index|
    source_id = row["rism_quell_id"].to_s.strip
    place_id = row["rism_place_id"].to_s.strip
    place_name = row["ort_name"].to_s.strip

    if source_id.empty? || place_id.empty?
      warn "Skipping CSV row #{index + 2}: missing source or place ID"
      next
    end

    source = Source.find_by(id: source_id)
    place = Place.find_by(id: place_id)
    unless source && place
      warn "Skipping CSV row #{index + 2}: source #{source_id} or place #{place_id} not found"
      next
    end

    source.marc.load_source
    source.marc.add_tag_with_subfields("751", "0": place_id, a: place_name, "8": "01")
    source.paper_trail_event = "Add 751 Geographic name places/#{place_id}"
    source.save!

    puts "Added 751 to #{source_id}"
  end
#end
