=begin
search=Person.solr_search do 
  fulltext("Unresolved", :fields=>["667a"]) 
  paginate :per_page=>50
end

rs={}

search.results.each do |line|
  content=""
  marc=line.marc
  marc.each_by_tag("667") do |t|
    content=t.fetch_first_by_tag("a").content
  end

  rs[line.id]=content
end

puts rs




puts rs.size
puts rs


=end

Person.all.each do |s|
  count=0
  marc = s.marc
  modified = false
  puts "OLD MARC ############################## OLD MARC"
  puts marc
  marc.each_by_tag("510") do |t|
  counter=0
    a = t.fetch_first_by_tag("a")
    if a 
      if a.content
        reference=a.content
        institution=Institution.where(siglum: reference).take
        if institution
          a.content=reference
          t.add(MarcNode.new(Person, "0", catalog.id, nil)) if !t.fetch_first_by_tag("0")
        #else
        #  puts counter+=1
        #  new_549 = MarcNode.new(Person, "667", "", "10")
        #  ip = marc.get_insert_position("667")
        #  count=0
        #  new_549.add_at(MarcNode.new(Person, "a", "Unresolved reference: "+reference, nil), count)

         # marc.root.children.insert(ip, new_549)
         # marc.root.destroy_child(t)
        end
        modified = true
    #  else
    #      new_549 = MarcNode.new("549", "", "10")
    #      ip = marc.get_insert_position("549")
    #      count=0
    #      new_549.add_at(MarcNode.new("a", a.content, nil), count)
    #      marc.root.children.insert(ip, new_549)
    #      t.destroy_child(a)

        modified = true
      end
    end
  
  

  end
  puts "NEW MARC ========================================"
  puts marc
  #s.save if modified

end
