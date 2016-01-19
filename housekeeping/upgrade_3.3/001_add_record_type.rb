require 'progress_bar'

pb = ProgressBar.new(Source.all.count)

Source.all.each do |sa|
  
  s = Source.find(sa.id)
  
  # convert to intergal marc
  s.marc.to_internal
  rt = s.marc.get_record_type
  if (rt)
    s.record_type = rt
  else
    "Empty record type for #{s.id}"
  end
  
  marc = s.marc
  
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
    t8.destroy_yourself
    tb.destroy_yourself
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
  
	s.suppress_update_77x
	s.suppress_update_count
  s.suppress_reindex
  
  begin
    s.save
  rescue => e
    puts e.message
  end
  
  pb.increment!
  
end