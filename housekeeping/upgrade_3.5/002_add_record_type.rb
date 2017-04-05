require 'progress_bar'

def parse_240n(s)
  catalog = ""
  opus = ""

  if s.downcase.include?("op.")
    if s.downcase.start_with?("op")
      # we have only an opus nr
      opus = s.strip
    else
      # try to split it
      if s.downcase.include?(",")
        parts = s.split(",")
        if parts.count == 2
      
          if parts[1].downcase.include?("op.")
            # Assume part 0 is the catalogue
            catalog = parts[0].strip
            opus = parts[1].strip
          else
            $stderr.puts "OP not in part 1 #{s}"
          end
      
        else
          $stderr. puts "Too many \",\": #{s}"
        end
      else
        $stderr.puts "String contains op, but not after comma: #{s}"
      end
    end

  else
    catalog = s.strip
  end

  #puts "#{s.strip} \t #{opus} \t #{catalog}"
  
  return opus
end

pb = ProgressBar.new(Source.all.count)

preserve508 = YAML::load(File.read("housekeeping/upgrade_3.5/508_conversion.yml"))
move505 = YAML::load(File.read("housekeeping/upgrade_3.5/505-520_conversion.yml"))


Source.all.each do |sa|
  
  s = Source.find(sa.id)
  s.paper_trail_event = "system upgrade"
  
  marc = s.marc
  marc.load_source(false)
  
  # convert to intergal marc
  # DO THIS AT THE END!
#  marc.to_internal
#  rt = marc.record_type
  rt = marc.match_leader
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
  # NOTE EXPERIMENTAL: automatically parse
  marc.each_by_tag("240") do |t|
    tn = t.fetch_first_by_tag("n")
    
    next if !(tn && tn.content)
    
    opus = parse_240n(tn.content)
    next if opus.empty?
    
    new_383 = MarcNode.new("source", "383", "", "##")
    new_383.add_at(MarcNode.new("source", "b", opus, nil), 0)
    new_383.sort_alphabetically

    marc.root.children.insert(marc.get_insert_position("383"), new_383)
    
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
    
    next if !move505.include?(ta.content)
    #puts "#{s.id} moved 505"
    
    new_520 = MarcNode.new("source", "520", "", "##")
    new_520.add_at(MarcNode.new("source", "a", ta.content, nil), 0)
    new_520.sort_alphabetically

    marc.root.children.insert(marc.get_insert_position("520"), new_520)
    
    #adios
    t.destroy_yourself
  end
    
  # #207 Move 563 to 500
  # FIXME see #351
=begin
  marc.each_by_tag("563") do |t|

    node = t.deep_copy
    node.tag = "500"
    node.indicator = "##"
    node.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position("500"), node)
    
    t.destroy_yourself
  end
=end

  # #351 - instead of @207
  # Set them to the material group 01
  # It will have a special table to override where necessary
  marc.each_by_tag("563") do |t|
    t.add_at(MarcNode.new("source", "8", "01", nil), 0)
    t.sort_alphabetically
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
  
  # 359 - move or delete, 508
  if preserve508.has_key?(s.id)
    # Item in the preserve list. Whould 508 be kept?
    content = preserve508[s.id]
    marc.each_by_tag("508") do |t|
      tn = t.fetch_first_by_tag("a")
      if content.include?(tn.content)
        # In the list, preserve it
        node = t.deep_copy
        node.tag = "500"
        node.indicator = "##"
        node.sort_alphabetically
        marc.root.children.insert(marc.get_insert_position("500"), node)
      end
      # Drop the 508
      t.destroy_yourself
    end
  else
    # Item not in the preserve list. Kill all 508
    marc.each_by_tag("508") {|t| t.destroy_yourself}
  end

  #398 Migrate 653 to 595
  # Save, for convenience, the contents of 595
  marc.each_by_tag("653") do |t|
    ta = t.fetch_first_by_tag("a")
    
    next if !(ta && ta.content)
    
    new_595 = MarcNode.new("source", "595", "", "##")
    # 1) 653 $a should go to 595 $u as it is
    new_595.add_at(MarcNode.new("source", "u", ta.content, nil), 0)
    
    # 2) 653 $a also to 595 $a but without information in parenthesis (voice)
    parts = ta.split("(")
    if parts.count > 0 # it contains a (
      # We preserve the fist part
      new_595.add_at(MarcNode.new("source", "a", parts[0].strip, nil), 0)
    end
    
    new_595.sort_alphabetically

    marc.root.children.insert(marc.get_insert_position("595"), new_595)
    
    #adios
    t.destroy_yourself
  end
  
  # Drop $2pe in 031, see #194
  #398 migrate 031 $e to 595, without diplicates
  marc.each_by_tag("031") do |t|
    # First, drop the $2
    st = t.fetch_first_by_tag("2")
    if st && st.content && st.content != "pe"
      puts "Unknown 031 $2 value: #{st.content}"
    end
    st.destroy_yourself if st
    
    # Now take care of the $e
    # duplicate 031$e to 595 $a (delete double entries)
    se = t.fetch_first_by_tag("e")
    next if !(se && se.content) 
    found = false
    # Go though the 595. We could already have had some
    marc.each_by_tag("595") do |t595|
       sa = t595.fetch_first_by_tag("a")
       next if !(sa && sa.content)
       if sa.content == se.content
         found = true
         break
       end
    end
    
    # No duplicate, create new with the content of 031 $e
    if !found
      new_595 = MarcNode.new("source", "595", "", "##")
      new_595.add_at(MarcNode.new("source", "a", se.content, nil), 0)
      new_595.sort_alphabetically
      marc.root.children.insert(marc.get_insert_position("595"), new_595)
    end
    ## NOTE 031 $e is DUPCATE and NOT deleted
    
  end
  
  # #208, drop 600
  marc.each_by_tag("600") {|t| t.destroy_yourself}
  
	s.suppress_update_77x
	s.suppress_update_count
  s.suppress_reindex
  
  # Convert marc to the internal format
  marc.to_internal
  
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
