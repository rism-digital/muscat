def change_tag(item, tag, subtag, old, new)
  model = item.marc.instance_variable_get(:@model)
  item.marc[tag].each do |t|
    tt = t[subtag]&.first
    if tt && tt.content.to_s == old.to_s
      puts "#{item.class} #{item.id} change #{tag} $#{subtag} #{old} to #{new}"
      #tt.content = new.to_s 
      tt.destroy_yourself
      t.add_at(MarcNode.new(model, "0", new, nil), 0 )
    end
  end
  item.paper_trail_event = "Change Place #{old} to #{new}"
  item.save
end

f = Folder.new(:name => "Places to delete " + DateTime.now.to_s, :folder_type => "Place", wf_owner: 1)
f.save

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
 
  puts "Keep #{top_id} delete #{other_ids.inspect}"

  other_ids.each do |change_place|
    cp = Place.find(change_place)

    f.add_item(cp)

    cp.referring_sources.each do |s|
      change_tag(s, "651", "0", change_place, top_id)
    end

    cp.referring_people.each do |s|
      s = Person.find(s.id)
      change_tag(s, "551", "0", change_place, top_id)
      s = Person.find(s.id)
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

puts f.name
puts f.id