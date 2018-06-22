alles_title = []
Source.all.each do |s|

  modified = false

=begin
  s.marc.by_tags("518").each do |t|

  t.fetch_all_by_tag("a").each do |ta|
  next if !ta || !ta.content
  #ap ta.content
      
  begin
  lang =  s.marc.first_occurance("040", "b").content 
  rescue 
  ap " #{s.id}"
  end
  ap lang unless lang == "ger"
  end
    
  end
=end

#549
  tags = {
    "031": "d",
    "245": "a",
    "246": 'a',
    "300": 'a',
    "500": 'a',
    "505": 'a',
    "518": 'a',
    "525": 'a',
    "561": 'a',
  }

excludes = [402003662,
            402003676,
            402003685,
            402003686,
            402003690,
            402003701,
            402003823,
            402003916,
            402006437]

  tags.each do |tag, subtag|
    next if excludes.include?(s.id)
    
    s.marc.by_tags(tag.to_s).each do |t|

      t.fetch_all_by_tag(subtag).each do |ta|
        next if !ta || !ta.content
        mtch = ta.content.scan(/[a-zA-Z0-9]\|[a-zA-Z0-9]{2,99}.+?\s/)
        next if mtch.count == 0

        content = ta.content
        mtch.each do |m|
          
          toks =  m.strip.split("|")
          new_str =  toks[0] + "|" + toks[1].split("").join("|") + " "
          
          content.gsub!(m, new_str)
          
        end
        ta.content = content
        modified = true
        #puts "#{s.id}\t#{content}" if  mtch.count > 1
      end
        
    end
  end

  # 548
  if s.record_type == 1 #collection

    # Collections with no 100 but with only one author
#    if s.composer.empty?
#      a = []
#      s.child_sources.each do |rs|
#        a << rs.composer
#      end
#      a.sort!.uniq!
#      if a.count == 1
#        puts "#{s.id} #{a[0]}" if a[0] != "Anonymus"
#      end
#    end
    
    name = s.marc.first_occurance("100", "a")
    next if !name || !name.content
    
    children_material = []
    
    #puts name.content
    found = true
    s.child_sources.each do |rs|
      #puts "#{s.id}: expected #{s.composer} found #{rs.composer}" if rs.composer != name.content
      found = false if rs.composer != name.content
      
      authman = rs.marc.first_occurance("593", "a")
      found = false if !authman || !authman.content || !authman.content.include?("Autograph")
      children_material << rs.marc.by_tags("593").count
    end
    
    total = [s.marc.by_tags("593").count].concat children_material
    if total.sort.uniq.count > 1
      puts "#{s.id} has #{s.marc.by_tags("593").count} groups, children have: #{children_material.to_s}".yellow
    end
    
    if found
      # Remove the old one
      if s.marc.by_tags("593").count == 1
         s.marc.by_tags("593").each {|t| t.destroy_yourself}
         
         new_593 = MarcNode.new("source", "593", "", "##")
         new_593.add_at(MarcNode.new("source", "a", "Autograph manuscript", nil), 0)
         new_593.add_at(MarcNode.new("source", "8", "01", nil), 0)
         new_593.sort_alphabetically
         s.marc.root.children.insert(s.marc.get_insert_position("593"), new_593)
         
         modified = true
      end
      
    end
    
  end

  #puts s.id if modified
  #s.save! if modified
end

=begin
StandardTitle.all.each do |st|
  next if st.referring_sources.count == 0
  if st.title.include?(",")
    tok = st.title.split(",")
    next if tok[1].strip.length > 4
    t = tok[1].strip[-1] == "'" ? tok[1].strip : tok[1].strip + " "
    puts "#{st.id}\t#{t.length}\t#{st.title}\t#{t}#{tok[0]}"
  end
end
=end