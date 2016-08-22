require 'progress_bar'

pb = ProgressBar.new(Source.all.count)

Source.all.each do |sa|
  
  s = Source.find(sa.id)
  
  marc = s.marc
  marc.load_source(false)
  
  # convert to intergal marc
  marc.to_internal
  rt = marc.record_type
  if (rt)
    s.record_type = rt
  else
    "Empty record type for #{s.id}"
  end
  
  #204 Move 300 $b to 500
  marc.each_by_tag("300") do |t|
    t8 = t.fetch_first_by_tag("8")
    tb = t.fetch_first_by_tag("b")
    
    next if !(t8 && t8.content) || !(tb && tb.content)
    
    new_500 = MarcNode.new("source", "500", "", "##")
    new_500.add_at(MarcNode.new("source", "a", tb.content, nil), 0)
    new_500.add_at(MarcNode.new("source", "8", t8.content, nil), 1)
    new_500.sort_alphabetically

    marc.root.children.insert(marc.get_insert_position("500"), new_500)
    
    #adios
    tb.destroy_yourself
  end
  
  #339 Migrate 240 $n to 383 $b
  marc.each_by_tag("240") do |t|
    tn = t.fetch_first_by_tag("n")
    
    next if !(tn && tn.content)
    
    new_383 = MarcNode.new("source", "383", "", "##")
    new_383.add_at(MarcNode.new("source", "b", tn.content, nil), 0)
    new_383.sort_alphabetically

    marc.root.children.insert(marc.get_insert_position("383"), new_500)
    
    #adios
    tn.destroy_yourself
  end
  
  all300 = marc.root.fetch_all_by_tag("300")
  all300.each do |t|
    if t.all_children.count == 1
      puts "Removed 300 with ony $8: #{s.id}"
      t.destroy_yourself
    end
  end
  
  #191 Remove 730 $r $n $m 
  marc.each_by_tag("730") do |t|
    t.fetch_all_by_tag("r").each {|st| st.destroy_yourself}
    t.fetch_all_by_tag("n").each {|st| st.destroy_yourself}
    t.fetch_all_by_tag("m").each {|st| st.destroy_yourself}
  end
  
  #198 Remove 110 for collections
  if s.record_type == MarcSource::RECORD_TYPES[:collection] || MarcSource::RECORD_TYPES[:convolutum]
    marc.each_by_tag("110") {|t| t.destroy_yourself}
  end 
  
  #202 Map 100 $j and 700 $j
  marc.each_by_tag("100") do |t|
    tj = t.fetch_first_by_tag("j")
    
    if tj && tj.content && tj.content == "Attributed to"
      tj.destroy_yourself #adios
      t.add_at(MarcNode.new("source", "j", "Doubtful", nil), 0)
      t.sort_alphabetically
    end
  end
  
  # Migrate 852 $0 to $x
  marc.each_by_tag("852") do |t|
    t0 = t.fetch_first_by_tag("0")
    
    if !(t0 && t0.content)
      puts "WARN: 852 without $0 #{s.id}"
      next
    end
    
    t.add_at(MarcNode.new("source", "x", t0.content, nil), 0)
    t.sort_alphabetically
    
    #adios
    t0.destroy_yourself
  end
  
  #193 Migrate 505 to 520
  marc.each_by_tag("505") do |t|
    ta = t.fetch_first_by_tag("a")
    
    next if !(ta && ta.content)
    
    new_520 = MarcNode.new("source", "520", "", "##")
    new_520.add_at(MarcNode.new("source", "a", ta.content, nil), 0)
    new_520.sort_alphabetically

    marc.root.children.insert(marc.get_insert_position("500"), new_520)
    
    #adios
    t.destroy_yourself
  end
  
  # Drop $2pe in 031, see #194
  marc.each_by_tag("031") do |t|
    st = t.fetch_first_by_tag("2")
    if st && st.content && st.content != "pe"
      puts "Unknown 031 $2 value: #{st.content}"
    end
    st.destroy_yourself if st
  end
  
  
  # #207 Move 563 to 500
  marc.each_by_tag("563") do |t|

    node = t.deep_copy
    node.tag = "500"
    node.indicator = "##"
    node.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position("500"), node)
    
    t.destroy_yourself
  end
  
  # #192 move 594 to 598
  marc.each_by_tag("594") do |t|

    node = t.deep_copy
    node.tag = "598"
    node.indicator = "##"
    node.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position("598"), node)
    
    t.destroy_yourself
  end
  
  # #208, drop 600
  marc.each_by_tag("600") {|t| t.destroy_yourself}
  
	s.suppress_update_77x
	s.suppress_update_count
  s.suppress_reindex
  
  new_marc_txt = marc.to_marc
  new_marc = MarcSource.new(new_marc_txt, s.record_type)
  s.marc = new_marc
  #puts new_marc
  
  #begin
    s.save
    #rescue => e
    #puts e.message
    #end
  
  pb.increment!
  
end