require "csv"

input = File.join(__dir__, "enhance_list.tsv")
output = File.join(__dir__, "enhance_list_588.tsv")
count = 0
headers = %w[psmd_id muscat_id muscat_link 588_a child_record_count marc_tag_count]

CSV.open(output, "wb", col_sep: "\t", headers: headers, write_headers: true) do |out|
  CSV.foreach(input, col_sep: "\t", headers: %i[psmd_id muscat_id]) do |row|
    source = Source.find_by_id(row[:muscat_id].to_i)
    next unless source

    all_tags = source.marc.all_tags(false)
    tags_588 = all_tags.select { |tag| tag.tag == "588" }
    next if tags_588.empty?

    values_588 = tags_588.flat_map { |tag| tag["a"]&.map(&:content) || [] }.compact.join("; ")
    link = "https://muscat.rism.info/admin/manuscripts/#{row[:muscat_id]}"
    child_count = source.child_sources.count
    marc_tag_count = all_tags.count

    out << [row[:psmd_id], row[:muscat_id], link, values_588, child_count, marc_tag_count]
    count += 1
  end
end

puts "Wrote #{count} records to #{output}"
