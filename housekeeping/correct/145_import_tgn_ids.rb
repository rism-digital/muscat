def delete_024_tgn(marc)
  marc["024"].each do |t|
    if t["2"]&.first&.content == "TGN"
      t.destroy_yourself
    end
  end
end

#Place.find_each {|p| p.scaffold_marc; p.save if p.changed?}

def output_tsv_line(*args)
  puts CSV.generate_line(args, col_sep: "\t")
end

name = ARGV[0]

CSV::foreach(name) do |line|
  tgn = line[1]&.gsub("tgn/", "")
  muscat = line[0]

  next if !muscat
  next if muscat.empty?

  next if !tgn
  next if tgn.empty?

  begin
    p = Place.find(muscat)
  rescue ActiveRecord::RecordNotFound
    #puts "-> #{muscat} was deleted".red
    output_tsv_line muscat, tgn, "RECORD DELETED"
    next
  end

  old_t = p.marc["024"]&.first
  old = old_t["a"]&.first&.content if old_t
  
  if old && old.to_s.strip != tgn.to_s.strip
    #puts "#{p.id} changed TGN from #{old} to #{tgn}"
    output_tsv_line muscat, tgn, "CHANGED", "old:#{old}"
    next
  end

  if old && old.to_s.strip == tgn.to_s.strip
    #output_tsv_line muscat, tgn, "UNCHANGED"
    next
  end

  delete_024_tgn(p.marc)
  p.marc.add_tag_with_subfields("024", a: tgn, "2": "TGN")

  p.paper_trail_event = "Add TGN id #{tgn}"
  p.save
  
  output_tsv_line muscat, tgn, "ADDED"

end

# see 138_deduplicate places