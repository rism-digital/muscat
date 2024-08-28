SIGLUM_MAP = {
"Parstorffer 1653": 51003803,
"IRL Dmh (in IRL Dtc)": 30003329,
"I-Vas, San Marco (1720)": 30001974,
"I-Vas": 30001974,
"Flurschütz 1613": 51003803,
"CH-Zz, AMG Archiv IV A 6": 30000014,
"CH-Zz, AMG Archiv IV A 3": 30000014,
"CH-W, Dep MK 303 [1722]": 30000013,
"CH-W, Dep MK 303 [1660]": 30000013,
"CH-SOa, St Leod. Prot. vol. 1": 30005638,
"CH-Lz, Pp Msc 11.4": 30000523,
"CH-La, KK 305": 51003803,
"CH-G AEG, Jur Civ F 300": 51003803,
"CH-BM, StiA Bd. 1206": 30000005,
"CH-Bischofszell, Museum [1744]": 51003803,
"CH-Bischofszell, Museum [1743]": 51003803,
"CH-BEa, OG Bern-Muenster 208": 30002638,
"CH-BEa, B III 873": 30002638,
"CH-A Stadtarchiv, II.562c": 30000001,
"B-Oa, SAO AC027 236": 30077340,
"A-FKsta, Akt Nr. 269": 30077027
}

SHELFMARK_MAP = {
"Parstorffer 1653": "Parstorffer 1653",
"IRL Dmh (in IRL Dtc)": "n.a.",
"I-Vas, San Marco (1720)": "San Marco (1720)",
"I-Vas": "n.a.",
"Flurschütz 1613": "Flurschütz 1613",
"CH-Zz, AMG Archiv IV A 6": "AMG Archiv IV A 6",
"CH-Zz, AMG Archiv IV A 3": "AMG Archiv IV A 3",
"CH-W, Dep MK 303 [1722]": "Dep MK 303 [1722]",
"CH-W, Dep MK 303 [1660]": "Dep MK 303 [1660]",
"CH-SOa, St Leod. Prot. vol. 1": "St Leod. Prot. vol. 1",
"CH-Lz, Pp Msc 11.4": "Pp Msc 11.4",
"CH-La, KK 305": "KK 305",
"CH-G AEG, Jur Civ F 300": "Jur Civ F 300",
"CH-BM, StiA Bd. 1206": "StiA Bd. 1206",
"CH-Bischofszell, Museum [1744]": "Museum [1744]",
"CH-Bischofszell, Museum [1743]": "Museum [1743]",
"CH-BEa, OG Bern-Muenster 208": "OG Bern-Muenster 208",
"CH-BEa, B III 873": "B III 873",
"CH-A Stadtarchiv, II.562c": "II.562c",
"B-Oa, SAO AC027 236": "SAO AC027 236",
"A-FKsta, Akt Nr. 269": "Akt Nr. 269"
}

inventories_db = YAML::load(File.read('database_export.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])

def slow_select(model_a, model_b, id_to_find, array)
return array
  .select { |item| item[model_a] == id_to_find }
  .map { |item| item[model_b] }
end

#ap slow_select("institution_id", "manuscript_id", 591, inventories_db["institutions_manuscripts"])

#ap slow_select("library_id", "manuscript_id", 6876, inventories_db["libraries_manuscripts"])


# Step 1, create new inventories in the Source template

inventories_db["libraries"].each do |inventory|

  muscat_inventory = Source.new
  muscat_inventory.record_type = MarcSource::RECORD_TYPES[:inventory]
  new_marc = MarcSource.new("", MarcSource::RECORD_TYPES[:inventory])

  mc = MarcConfigCache.get_configuration("source")

  siglum = SIGLUM_MAP[inventory["siglum"].strip.to_sym]
  shelfmark = SHELFMARK_MAP[inventory["siglum"].strip.to_sym]

  # Add Library info
  x852 = MarcNode.new("source", "852", "", mc.get_default_indicator("852"))
  x852.add_at(MarcNode.new("source", "x", siglum, nil), 0 )
  x852.add_at(MarcNode.new("source", "c", shelfmark, nil), 0 )
  x852.sort_alphabetically
  new_marc.root.add_at(x852, new_marc.get_insert_position("852") )

  # Title on src
  if inventory["address"] && !inventory["address"].empty?
    x245 = MarcNode.new("source", "245", "", mc.get_default_indicator("245"))
    x245.add_at(MarcNode.new("source", "a", inventory["address"], nil), 0 )
    x245.sort_alphabetically
    new_marc.root.add_at(x245, new_marc.get_insert_position("245") )
  end

  # variant title?
  x246 = MarcNode.new("source", "246", "", mc.get_default_indicator("246"))
  x246.add_at(MarcNode.new("source", "a", inventory["name"], nil), 0 )
  x246.sort_alphabetically
  new_marc.root.add_at(x246, new_marc.get_insert_position("246") )

  # 240 Inventory
  x240 = MarcNode.new("source", "240", "", mc.get_default_indicator("240"))
  x240.add_at(MarcNode.new("source", "0", 3930931, nil), 0 )
  x240.sort_alphabetically
  new_marc.root.add_at(x240, new_marc.get_insert_position("240") )

  # 650 Standard Term
  x650 = MarcNode.new("source", "650", "", mc.get_default_indicator("650"))
  x650.add_at(MarcNode.new("source", "0", 3025686, nil), 0 )
  x650.sort_alphabetically
  new_marc.root.add_at(x650, new_marc.get_insert_position("650") )

  new_marc.suppress_scaffold_links
  new_marc.import

  muscat_inventory.marc = new_marc
  muscat_inventory.save
  muscat_inventory.reindex
  
  i2 = Source.find(muscat_inventory.id)
  i2.save
end

Sunspot.commit