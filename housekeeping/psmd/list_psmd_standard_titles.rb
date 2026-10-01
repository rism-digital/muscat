require "csv"

output_path = ARGV.fetch(0, Rails.root.join("psmd_standard_titles.tsv").to_s)

CSV.open(output_path, "w", col_sep: "\t", headers: ["id", "standard title", "sources"], write_headers: true) do |tsv|
  StandardTitle
    .where("notes LIKE ?", "%Created from PSMD%")
    .find_each do |standard_title|
      source_ids = standard_title.referring_sources.order(:id).pluck(:id)

      tsv << [standard_title.id, standard_title.title, source_ids.join(",")]
    end
end

puts "Wrote #{output_path}"
