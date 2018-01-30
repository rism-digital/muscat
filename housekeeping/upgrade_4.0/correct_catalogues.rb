we_the_people = []
Catalogue.where("created_at > '2017-10-11'").where("created_at < '2017-10-12'").each do |c|
  we_the_people.concat c.referring_people
end

ap we_the_people.count

we_the_people.uniq!

we_the_people.each do |pers|
  ap "#{pers.id} #{pers.lock_version}"
  marc = pers.marc

  marc.by_tags("670").each {|t| t.destroy_yourself}

  pers.save
end