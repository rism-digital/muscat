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
    #delete_024_tgn(p.marc)
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

exit 1

dup_tgn_ids = Place.where.not(tgn_id: nil)
                   .group(:tgn_id)
                   .having("COUNT(*) > 1")
                   .pluck(:tgn_id)

tgn_to_place_ids = Place.where(tgn_id: dup_tgn_ids)
                        .group_by(&:tgn_id)
                        .transform_values { |places| places.map(&:id) }

tgn_to_place_ids.each do |k, v|

  # Count the total references to each obj
  refs = v.map do |id|
    p = Place.find(id)
    {count: p.through_associations_total_count, id: id}
  end

  # "top" is the one with the highes ref count
  # We will keep this is
  top = refs.max_by { |h| h[:count] }
  top_id = top[:id]
  # Other ids will be changed to top_id
  other_ids = refs.reject { |h| h.equal?(top) }.map { |h| h[:id] }
 
  #puts "Keep #{keeo_place_id} delete #{v.inspect}"

  other_ids.each do |change_place|
    cp = Place.find(change_place)

    cp.referring_sources.each do |s|
      change_tag(s, "651", "0", change_place, top_id)
    end

    cp.referring_people.each do |s|
      change_tag(s, "551", "0", change_place, top_id)
      change_tag(s, "651", "0", change_place, top_id)
    end
    
    cp.referring_institutions.each do |s|
      change_tag(s, "551", "0", change_place, top_id)
    end

    cp.referring_publications.each do |s|
      change_tag(s, "651", "0", change_place, top_id)
    end

    cp.referring_holdings.each do |s|
        change_tag(s, "651", "0", change_place, top_id)
    end
    cp.referring_works.each do |s|
      change_tag(s, "370", "0", change_place, top_id)
    end
  end

end