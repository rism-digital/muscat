InventoryItemSourceRelation.where(marc_tag: "930").each do |r|
    ii = r.inventory_item
    ii.marc.change_tag("930", "932")
    ii.marc.import
    ii.save
end