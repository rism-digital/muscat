mc = MarcConfigCache.get_configuration("inventory_item")

InventoryItem.all.each do |ii|
  
  the245 = ii.marc.by_tags("245")

  next if the245.count == 1
  
  the245.each_with_index do |t, i|

    # The first one stays a 245
    next if i == 0

    n500 = MarcNode.new("inventory_item", "500", "", mc.get_default_indicator("500"))
    n500.add_at(MarcNode.new("inventory_item", "a", "Further references: " + t.fetch_first_by_tag("a").content, nil), 0 )
    ii.marc.root.add_at(n500, ii.marc.get_insert_position("500") )

    # ciuss!
    t.destroy_yourself

  end

    #puts ii.marc

    puts ii.id
    ii.paper_trail_event = "Move multiple 245 to 500"
    ii.save
end