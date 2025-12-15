Person.find_each do |p|

  save = false

  # Move 678 to 680 note
  p.marc["678"].each do |t|
    p.marc.add_tag_with_subfields("680", a: t["a"]&.first&.content)
    save = true
  end

  # bye
  p.marc.by_tags("678").each {|t2| t2.destroy_yourself}

  p.marc["100"].each do |t|
    p.marc.add_tag_with_subfields("678", a: t["y"]&.first&.content)
    t["y"]&.first&.destroy_yourself
    save = true
  end

  p.save if save
  puts p.id if save
end