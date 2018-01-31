we_the_people = []
Catalogue.where("created_at > '2017-10-11'").where("created_at < '2017-10-12'").each do |c|
  we_the_people.concat c.referring_people
end

ap we_the_people.count

we_the_people.uniq!

we_the_people.each do |pers|
  ap "#{pers.id} #{pers.lock_version}"
  marc = pers.marc

  marc.by_tags("670").each do |t|

    node = t.deep_copy
    node.tag = "680"
    node.indicator = "##"
    
    st = node.fetch_first_by_tag("w")
    st.destroy_yourself if st
    
    node.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position("680"), node)
    
    t.destroy_yourself
  end
  
  pers.save
end

Catalogue.where("created_at > '2017-10-11'").where("created_at < '2017-10-12'").each do |c|
  ap "delete catalogue #{c.id}"
  c.destroy
end