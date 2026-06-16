def output_tsv_line(*args)
  puts CSV.generate_line(args, col_sep: "\t")
end

Place.find_each do |p|
  next if p.tgn_id.blank?

  old_name = p.name

  begin
    TgnClientJson.new.fetch_marc_place(p.tgn_id, p.marc)
  rescue
    output_tsv_line p.id, p.tgn_id, "ERROR"
    next
  end

  p.paper_trail_event = "Pulled Place data from TGN #{p.tgn_id}"
  p.save

  output_tsv_line p.id, p.tgn_id, "PULLED", old_name, p.name
end

# see 138_deduplicate places