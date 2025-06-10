mc = MarcConfigCache.get_configuration("inventory_item")

InventoryItem.all.each do |ii|
  
  the245 = ii.marc.by_tags("245")

  if the245.count > 1
    big = the245.map{|t| t.fetch_first_by_tag("a").content}.join("; ")
    the245.each {|t| t.destroy_yourself}


    a245 = MarcNode.new("inventory_item", "245", "", mc.get_default_indicator("245"))
    a245.add_at(MarcNode.new("inventory_item", "a", big, nil), 0 )

    ii.marc.root.add_at(a245, ii.marc.get_insert_position("245") )


    puts ii.id
    ii.paper_trail_event = "Concatenate multiple 245"
    ii.save
  end

end