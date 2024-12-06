pb = ProgressBar.new(Institution.all.count)
Institution.find_in_batches do |batch|

  batch.each do |s|
    pb.increment!

    s.marc.load_source false

    the_t = s.marc.first_occurance("110", "g")
    next if !the_t || !the_t.content

    # Create the 094
    n094 = MarcNode.new("institution", "094", "", "7#")
    n094.add_at(MarcNode.new("institution", "a", the_t.content, nil), 0)
    n094.add_at(MarcNode.new("institution", "q", "siglum", nil), 0)
    n094.add_at(MarcNode.new("institution", "2", "rism", nil), 0)
    n094.sort_alphabetically
    s.marc.root.children.insert(s.marc.get_insert_position("094"), n094)

    # Remove the old $g
    t110 = s.marc.first_occurance("110")
    t110.each_by_tag("g") {|t| t.destroy_yourself}

    s.save
  end

end
