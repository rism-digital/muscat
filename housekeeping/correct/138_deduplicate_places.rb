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
  item.paper_trail_event = "Change Place #{old} to #{new} in tag #{tag}"
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
    next if p.through_associations_total_count == 0
    {count: p.through_associations_total_count, id: id}
  end.compact

  # "top" is the one with the highes ref count
  # We will keep this is
  top = refs.max_by { |h| h[:count] }
  top_id = top[:id]
  # Other ids will be changed to top_id
  other_ids = refs.reject { |h| h.equal?(top) }.map { |h| h[:id] }

  if other_ids.empty?
    #puts "Other ids have no assosiations, were they already moved away?"
    next
  end

  puts "Keep #{top_id} delete #{other_ids.inspect}"

  other_ids.each do |change_place|
    cp = Place.find(change_place)

    f.add_item(cp)

    # We want to call .save multiple times if meeded
    # on the same model, so we can have a different version
    source_ids = cp.referring_sources.pluck(:id)
    person_ids = cp.referring_people.pluck(:id)
    institution_ids = cp.referring_institutions.pluck(:id)
    publication_ids = cp.referring_publications.pluck(:id)
    holding_ids = cp.referring_holdings.pluck(:id)
    work_ids = cp.referring_works.pluck(:id)
    place_ids = cp.referring_places.pluck(:id)


    source_ids.each do |id|
      change_tag(Source.find(id), "651", "0", change_place, top_id)
    end

    person_ids.each do |id|
      %w[551 651].each do |tag|
        change_tag(Person.find(id), tag, "0", change_place, top_id)
      end
    end

    institution_ids.each do |id|
      change_tag(Institution.find(id), "551", "0", change_place, top_id)
    end

    publication_ids.each do |id|
      change_tag(Publication.find(id), "651", "0", change_place, top_id)
    end

    holding_ids.each do |id|
      change_tag(Holding.find(id), "651", "0", change_place, top_id)
    end

    work_ids.each do |id|
      change_tag(Work.find(id), "370", "0", change_place, top_id)
    end

    place_ids.each do |id|
      puts id
    end
  end

end

puts f.name
puts f.id