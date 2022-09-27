p_old = Place.all.count
c = Person.where("marc_source LIKE ?", "%=551%").count
pb = ProgressBar.new(c)

ActiveRecord::Base.connection.execute "ALTER TABLE places AUTO_INCREMENT=50010000"

Person.where("marc_source LIKE ?", "%=551%").each do |pe|
    #pe = Person.find(p.id)

    pe.marc.load_source false
    pe.marc.import
    pe.suppress_reindex
    PaperTrail.request(enabled: false) do
        pe.save
    end

    pb.increment!
end

p_new = Place.all.count

puts "Went from #{p_old} to #{p_new} places, #{p_new - p_old} were created"

pb = ProgressBar.new(p_new)
Place.all.each do |pp|
    pp.reindex
    pb.increment!
end

f = Folder.new(:name => "New Places", :folder_type => "Place", wf_owner: 1)
f.save
new_pl = Place.where("id >=  50010000")
f.add_items(new_pl)