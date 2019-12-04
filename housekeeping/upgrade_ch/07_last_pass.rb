puts "Restoring people"
people = YAML.load(File.read("migration_people_ids.yml"))
people.each do |id, user|
	ps = Person.find(id)
	ps.wf_owner = user
	ps.suppress_reindex
	ps.save
end

# and the catalogues
puts "Restoring catalogues"
catalogues = YAML.load(File.read("migration_catalogues.yml"))
catalogues.each do |id, marc|
	c = Catalogue.find(id)
	c.marc_source = marc
	c.marc.load_source(false)
	c.marc.import
	c.suppress_reindex
	c.save
end
puts "done"

pb = ProgressBar.new(Source.where("id > 400000000 and id < 420000000").count)

Source.where("id > 400000000 and id < 420000000").each do |se|
	s = Source.find(se.id) 
	#puts s.id
	pb.increment!
	s.marc.load_source(true)

	s.suppress_reindex
	s.suppress_update_77x
	s.suppress_update_count
	s.paper_trail_event = "CH Finalize Migration"
	s.save
	s = nil
end
