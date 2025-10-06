InventoryItem.all.each do |ii|
  
  save = false

  ii.marc["691"].each do |lib|
    lib["0"].each do |t|
       if t.content == 51003911
         t.destroy_yourself
         lib.add_at(MarcNode.new("inventory_item", "0", 50006603, nil), 0 )
         save = true
       end
       save = true if t.content == 50006603
    end
  end

  if save

    ii.marc.import
    
    ii.paper_trail_event = "Migrate PSMD 51003911 to 50006603"
    ii.save
    puts "Saved #{ii.id}"
  end

end