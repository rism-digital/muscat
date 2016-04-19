pb = ProgressBar.new(Source.all.count)

Source.all.each do |source|
  
  marc = source.marc
  marc.load_source
  
  marc.each_by_tag("852") do |t|
    
    # Make a nice new holding record
    holding = Holding.new    
    new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
    new_marc.load_source false
    
    # Kill old 852s
    new_marc.each_by_tag("852") {|t2| t2.destroy_yourself}
    
    new_852 = t.deep_copy
    new_marc.root.children.insert(new_marc.get_insert_position("852"), new_852)
    
    new_marc.suppress_scaffold_links
    new_marc.import
    
    holding.marc = new_marc
    holding.source = source
    holding.save
    
    t.destroy_yourself #adios
  end
  
  source.save
  
  pb.increment!
  
end