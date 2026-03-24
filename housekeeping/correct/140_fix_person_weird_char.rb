Person.find_each do |ps|
  save = false

  ps.marc["670"].each do |t|
    if t["b"]&.first&.content == "]"
      t.destroy_yourself
      save = true
    end
  end

  if save
    puts "save #{ps.id}"
    ps.paper_trail_event = "Remove 670 ]"
    ps.save
  end
end

Person.find_each do |ps|
  save = false

  name = ps.marc["100"].first["a"]&.first&.content
  date = ps.marc["100"].first["d"]&.first&.content

  ps.marc["670"].each do |t|
    if t["b"]&.first&.content == "="
      t["b"].first.content = "#{name} [#{date}]"
      save = true
    end
  end

  if save
    puts "save #{ps.id}"
    ps.paper_trail_event = "Expand 670 ="
    ps.save
  end
end