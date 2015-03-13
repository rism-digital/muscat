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

#=begin
counter=0
del=[]
Person.all.each do |s|
  print "\r#{counter+=1}: #{s.id}"
  count=0
  begin
    marc = s.marc
  rescue Exception
    puts "#{s.id}"
    del<< s
  end
  modified = false
  puts "OLD MARC ############################## OLD MARC"
  puts marc
  marc.each_by_tag("670") do |t|
    a = t.fetch_first_by_tag("a")
    if a 
      #if t.fetch_first_by_tag("b")
       # next
      #end
      if a.content.include?(": ")

        reference=a.content.split(": ")[0]
        finding=a.content.split(": ")[1]  
        catalog=Catalogue.where(name: reference).take
        if catalog
          #t.destroy_child(a)
          t.add(MarcNode.new(Person, "b", finding, nil)) if !t.fetch_first_by_tag("b")
          t.add(MarcNode.new(Person, "0", catalog.id, nil)) if !t.fetch_first_by_tag("0")
          a.content = reference
        else
          new_549 = MarcNode.new(Person, "667", "", "10")
          ip = marc.get_insert_position("667")
          count=0
          new_549.add_at(MarcNode.new(Person, "a", "Unresolved reference: "+reference, nil), count)

          marc.root.children.insert(ip, new_549)
          marc.root.destroy_child(t)
        end
        modified = true
    #  else
    #      new_549 = MarcNode.new("549", "", "10")
    #      ip = marc.get_insert_position("549")
    #      count=0
    #      new_549.add_at(MarcNode.new("a", a.content, nil), count)
    #      marc.root.children.insert(ip, new_549)
    #      t.destroy_child(a)
      end
    end
  
  

  end
  puts "NEW MARC ========================================"
  puts marc
  #s.suppress_recreate
  #s.save if modified

end

puts del.size
del.each do |pers|
  Person.delete(pers)
end
#=end
