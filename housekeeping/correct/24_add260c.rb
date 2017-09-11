Source.where(record_type: 3).each do |s|

  s.paper_trail_event = "Migrate 511"

  marc = s.marc
  marc.load_source

  # To make a diff
  File.write("diffmarc260/old/" + s.id.to_s + '.txt', s.marc.to_marc)

  xt = marc.root.fetch_all_by_tag("260")
	
  if xt.empty?
    puts s.id
    ## add the 260
    new_tag = MarcNode.new("source", "260", "", "##")
    new_tag.add_at(MarcNode.new("source", "c", "[s.d.]", nil), 0)
    new_tag.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position("260"), new_tag)
  end

  s.save
  ### Similarly for a diff 
  File.write("diffmarc260/new/" + s.id.to_s + '.txt', s.marc.to_marc)
end

puts "REMEMBER TO CHANGE THE RECORD ID!"