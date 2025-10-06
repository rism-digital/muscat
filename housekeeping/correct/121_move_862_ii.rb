InventoryItem.find_each(batch_size: 500) do |ii|
  
  #puts ii.id
  #puts ii.marc["852"]

  ta = ii.marc["852"].first["a"].first
  td = ii.marc["852"].first["d"].first
  tp = ii.marc["852"].first["p"].first


  t773 = ii.marc["773"].first

  t773.add_at(MarcNode.new("inventory_item", "o", ta.content, nil), 0 ) if ta && ta.content
  t773.add_at(MarcNode.new("inventory_item", "n", td.content, nil), 0 ) if td && td.content
  t773.add_at(MarcNode.new("inventory_item", "g", tp.content, nil), 0 ) if tp && tp.content
  t773.sort_alphabetically

  #ta.destroy_yourself if ta
  #td.destroy_yourself if td
  #tp.destroy_yourself if tp

  ii.marc["852"].first.destroy_yourself

  #puts ii.marc["773"]
  #puts
  
  ii.save
end