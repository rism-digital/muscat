Person.find_each do |ps|
  save = false

  ps.marc["670"].each do |t|
    st = t["b"]&.first&.content
    if st == "0" # NO! || st == "]"
      ps.marc.add_tag_with_subfields("675", "0": t["w"].first.content)
      t.destroy_yourself
      save = true
    end
  end

  if save
    puts ps.id
    ps.paper_trail_event = "Migrate 670 0 to 675"
    ps.save
  end

end