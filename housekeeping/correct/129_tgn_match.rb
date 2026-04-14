def delete_024_tgn(marc)
  marc["024"].each do |t|
    if t["2"]&.first&.content == "TGN"
      t.destroy_yourself
    end
  end
end

Place.find_each {|p| p.scaffold_marc; p.save if p.changed?}

name = ARGV[0]

CSV::foreach(name) do |line|
  tgn = line[0]&.gsub("tgn/", "")
  muscat = line[1]

  next if !muscat
  next if muscat.empty?

  next if !tgn
  next if tgn.empty?

  begin
    p = Place.find(muscat)
  rescue ActiveRecord::RecordNotFound
    puts "-> #{muscat} was deleted".red
    next
  end

  if p.tgn_id && !p.tgn_id.empty? && p.tgn_id != tgn
    #puts "TGN Id changed for #{muscat}, was #{p.tgn_id} will be #{tgn.to_i}"
    delete_024_tgn(p.marc)
  end
  # Just add the tag
  p.marc.add_tag_with_subfields("024", a: tgn, "2": "TGN")
=begin
TURN THIS ON TO GET TGN DATA
    #p.marc.add_tag_with_subfields("024", a: tgn, "2": "TGN")
  elsif !p.tgn_id || p.tgn_id.empty?
    puts "Pull #{tgn} for #{p.id}"
    rec = TgnClient::pull_from_tgn(tgn)
    if !rec
      puts "Could not pull record #{tgn} muscat id: #{p.id}".magenta
      next
    end
    TgnConverter::to_place_marc(rec, p.marc)
    #p.marc.add_tag_with_subfields("024", a: tgn, "2": "TGN")
  end
=end
  p.save
end

def change_tag(item, tag, subtag, old, new)
  item.marc[tag].each do |t|
    tt = t[subtag]&.first
    if tt && tt.content.to_s == old.to_s
      puts "#{item.class} #{item.id} change #{tag} $#{subtag} #{old} to #{new}"
      tt.content = new.to_s 
    end
  end
end

# see 138_deduplicate places