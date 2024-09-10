require "rexml/document" 
include REXML

class REXML::Element

  def inner_texts
   REXML::XPath.match(self,'.//text()')
  end
 
  def inner_text
   REXML::XPath.match(self,'.//text()').join 
  end
 
 end

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

@publication_map = {
"51000117":	143,
"51000692":	844,
"51001039":	1272,
"51001146":	1395,
"51002568":	3046,
"51002801":	3332,
"51003879":	40000046,
"51003883":	30029269,
"51003892":	30016916,
"51003894":	3582,
"51003900":	41000451,
"51003917":	30029272,
"51003183": 3806,
"51003292": 30000057,

}

@migrate_catalogs = %w(
51000117
51000692
51001039
51001146
51002568
51002801
51003183
51003292
51003850
51003852
51003876
51003877
51003878
51003879
51003881
51003882
51003883
51003884
51003885
51003886
51003887
51003889
51003890
51003891
51003892
51003893
51003894
51003895
51003896
51003897
51003898
51003899
51003900
51003901
51003902
51003903
51003904
51003905
51003906
51003907
51003908
51003909
51003910
51003911
51003914
51003915
51003916
51003917)

@series_map = {
  "Montfort": 30027220,
  "Rivista italiana di musicologia": 1504,
  "Early Music": 30026189,
  "Fonti musicali italiane": 30026214,
  "Kirchenmusikalisches Jahrbuch": 486,
  "Recercare": 30028117,
  "Musik in Geschichte und Gegenwart": 1263,
  "Dizionario Biografico degli Italiani": 2955,
  "Music & Letters": 279,
  "Studi musicali": 30026276,
  "Studi Musicali": 30026276
}

@fixed_stdterm_map = {
  "00000410001784": 3900056,
  "00000410001795": 3900056,
  "00000410001827": 3900056,
  "00000410001829": 3900056,
  "00000410001830": 25309,
  "00000410001831": 25178,
  "00000410001832": 25178,
  "00000410001834": 25178,
  "00000410001835": 25233,
  "00000410001910": 25257,
  "00000410001911": 25233
}

@manifest_map = {
  "A-FKsta_description.xml": ["A_FKsta_Akt_Nr_269.json"],
  "B-Oa_description.xml": ["B_Oa.json"],
  "CH_A_description.xml": ["CH_A_Stadtarchiv_II_562_c.json"],
  "CH_BEa_1697_description.xml": ["CH_BEa_B_III_873.json", "berne_1697_wm.json"],
  "CH_BEa_1761_description.xml": ["CH_BEa_OG_Bern_Muenster_208.json", "berne_1761_wm.json"],
  "CH_BM_description.xml": ["CH_BM_1206.json", "beromuenster_wm.json"],
  "CH_Bischofszell_description.xml": ["CH_Bischofszell_Museum_Diarium_1.json"],
  "CH_G_description.xml": ["CH-G_AEG.json"],
  "CH_Lz_description.xml": ["CH_Lz_Pp_Msc_11.json"],
  "CH_SOa_description.xml": ["CH_SOa_StLeodegar_Prot_Bd_1.json"],
  "CH_W_description.xml": ["CH_W_DepMK_303.json", "CH_W_DepMK_303-wm.json"],
  "CH_Zz_c_description.xml": ["CH_Zz_AMG_Archiv_IV_A_6_inv.json"],
  "CH_Zz_d_description.xml": ["CH_Zz_AMG_Archiv_IV_A_3_inv.json"],
  "Parstorffer_description.xml": ["Parstorffer.json"]
}

if ARGV[0] == "--cleanup"
  print "DO NOT DO THIS IN PRODUCTION Cleanup... "
  InventoryItem.find_by_sql("TRUNCATE TABLE inventory_items")
  Publication.where(created_at: Time.zone.yesterday.beginning_of_day..Time.zone.now.end_of_day).delete_all
  Person.where(created_at: Time.zone.yesterday.beginning_of_day..Time.zone.now.end_of_day).delete_all
  Institution.where(created_at: Time.zone.yesterday.beginning_of_day..Time.zone.now.end_of_day).delete_all
  Source.where(created_at: Time.zone.yesterday.beginning_of_day..Time.zone.now.end_of_day).delete_all
  puts "done"
end

print "Please stand while loading the db... "
@inventories_db = YAML::load(File.read('housekeeping/inventories_migration/database_export.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
@person_map = YAML::load(File.read('housekeeping/inventories_migration/inventory_people_map.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
@institution_map = YAML::load(File.read('housekeeping/inventories_migration/inventory_institution_map.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
@standard_term_map = YAML::load(File.read('housekeeping/inventories_migration/inventory_standard_term_map.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
@image_map = YAML::load(File.read('housekeeping/inventories_migration/ms2image.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])
puts "done"

@person_tags = ["100", "600", "700"]
@institution_tags = ["110", "710"]
@catalogue_tags = ["690", "691"]

def slow_select(model_a, model_b, id_to_find, array)
return array
  .select { |item| item[model_a] == id_to_find }
  .map { |item| item[model_b] }
end

def slow_find(column, id_to_find, array)
  return array.select { |item| item[column] == id_to_find }.first
end

def ms2inventory(source, library_id)

  mss = slow_select("library_id", "manuscript_id", library_id, @inventories_db["libraries_manuscripts"])
  mc = MarcConfigCache.get_configuration("source")

  mss.each do |ms_id|
    the_ms = slow_find("id", ms_id, @inventories_db["manuscripts"])

    inventory_item = InventoryItem.new
    inventory_item.source = source
    
    # Apply the right default file
    default_file = "default.marc"

    # Swap 246 and 245
    src_txt = the_ms["source"].gsub("=246", "=NEWTAG")
    src_txt = src_txt.gsub("=245", "=246")
    src_txt = src_txt.gsub("=246", "=245")

    new_marc = MarcInventoryItem.new(the_ms["source"])
    new_marc.load_source false # this will need to be fixed

    new_marc.by_tags("000").each {|t2| t2.destroy_yourself}
    new_marc.by_tags("003").each {|t2| t2.destroy_yourself}
    new_marc.by_tags("005").each {|t2| t2.destroy_yourself}
    new_marc.by_tags("007").each {|t2| t2.destroy_yourself}

    @person_tags.each do |t|
      new_marc.each_by_tag(t) do |tt|
        link_t = tt.fetch_first_by_tag("0")
        if @person_map.include? link_t.content
          link_t.destroy_yourself
          #link_t.content = @person_map[link_t.content].to_s
          #puts @person_map[link_t.content].to_s
          tt.add_at(MarcNode.new("inventory_item", "0", @person_map[link_t.content].to_s, nil), 0)
          #ap tt
        end
      end
    end

    @catalogue_tags.each do |t|
      new_marc.each_by_tag(t) do |tt|
        link_t = tt.fetch_first_by_tag("0")
        if @publication_map.include? link_t.content.to_sym
          link_t.destroy_yourself
          tt.add_at(MarcNode.new("inventory_item", "0", @publication_map[link_t.content.to_sym].to_s, nil), 0)
          #ap tt
        end
      end
    end

    @institution_tags.each do |t|
      new_marc.each_by_tag(t) do |tt|
        link_t = tt.fetch_first_by_tag("0")
        next if !link_t || !link_t.content
        if @institution_map.include? link_t.content
          link_t.destroy_yourself
          #link_t.content = @person_map[link_t.content].to_s
          #puts @institution_map[link_t.content].to_s
          tt.add_at(MarcNode.new("inventory_item", "0", @institution_map[link_t.content].to_s, nil), 0)
          #ap tt
        end
      end
    end

    # Some 710 are kust $4pbl. Nuke them
    nuke_list = []
    new_marc.each_by_tag("710") do |tt|
      if !tt.fetch_first_by_tag("0")
        nuke_list << tt if tt.fetch_first_by_tag("4").content == "pbl"
      end
    end
    nuke_list.each {|t| t.destroy_yourself}

    # Fix 650
    new_marc.each_by_tag("650") do |tt|
      link_t = tt.fetch_first_by_tag("0")
      # Some recrds have a hardcoded mapping
      if @fixed_stdterm_map.include?(the_ms["ext_id"].to_sym) && link_t.content == "51000330"
        link_t.destroy_yourself
        tt.add_at(MarcNode.new("inventory_item", "0", @fixed_stdterm_map[the_ms["ext_id"].to_sym].to_s, nil), 0)
      elsif @standard_term_map.include? link_t.content
        link_t.destroy_yourself
        tt.add_at(MarcNode.new("inventory_item", "0", @standard_term_map[link_t.content].to_s, nil), 0)
        #ap tt
      end
    end

    #add the images in 856
    if @image_map[the_ms["ext_id"]]
      @image_map[the_ms["ext_id"]].each do |image|
        next if image == "[spacer]"
        a856 = MarcNode.new("source", "856", "", mc.get_default_indicator("856"))
        a856.add_at(MarcNode.new("source", "u", "https://iiif.rism.digital/image/in/#{image}/full/full/0/default.jpg", nil), 0 )
        a856.add_at(MarcNode.new("source", "x", "Digitized", nil), 0 )
        a856.add_at(MarcNode.new("source", "z", "Link to page in the inventory", nil), 0 )
        a856.sort_alphabetically
        new_marc.root.add_at(a856, new_marc.get_insert_position("856") )
      end
    end

    # Add the 773 to the parent
    node = MarcNode.new("inventory_item", "773", "", "18")
    node.add_at(MarcNode.new("inventory_item", "w", inventory_item.source.id, nil), 0)
    new_marc.root.children.insert(new_marc.get_insert_position("773"), node)

    new_marc.import

    inventory_item.created_at = the_ms["created_at"]
    inventory_item.updated_at = the_ms["updated_at"]

    inventory_item.marc = new_marc
    inventory_item.save

  end

end

#ap slow_select("institution_id", "manuscript_id", 591, inventories_db["institutions_manuscripts"])

#ap slow_select("library_id", "manuscript_id", 6876, inventories_db["libraries_manuscripts"])

# Step 0, migrate the missing Publications/Catalogues
@inventories_db["catalogues"].each do |catalogue|
  next if @publication_map[catalogue["ext_id"].to_s.to_sym] != nil
  next if !@migrate_catalogs.include?(catalogue["ext_id"].to_s)

  #puts catalogue["ext_id"]

  mc = MarcConfigCache.get_configuration("publication")

  new_marc = MarcPublication.new()
  id = MarcNode.new("publication", "001", catalogue["ext_id"], "")

  new_marc.root.add_at(id, new_marc.get_insert_position("001") )

  x100 = MarcNode.new("publication", "100", "", mc.get_default_indicator("100"))
  x100.add_at(MarcNode.new("publication", "a", catalogue["author"], nil), 0 )
  x100.sort_alphabetically
  new_marc.root.add_at(x100, new_marc.get_insert_position("100") )

  x240 = MarcNode.new("publication", "240", "", mc.get_default_indicator("240"))
  x240.add_at(MarcNode.new("publication", "a", catalogue["description"], nil), 0 )
  x240.sort_alphabetically
  new_marc.root.add_at(x240, new_marc.get_insert_position("240") )

  x210 = MarcNode.new("publication", "210", "", mc.get_default_indicator("210"))
  x210.add_at(MarcNode.new("publication", "a", catalogue["name"], nil), 0 )
  x210.sort_alphabetically
  new_marc.root.add_at(x210, new_marc.get_insert_position("210") )

  if catalogue["pages"] && !catalogue["pages"].empty?
    x300 = MarcNode.new("publication", "300", "", mc.get_default_indicator("300"))
    x300.add_at(MarcNode.new("publication", "a", catalogue["pages"], nil), 0 )
    x300.sort_alphabetically
    new_marc.root.add_at(x300, new_marc.get_insert_position("300") )
  end

  x260 = MarcNode.new("publication", "260", "", mc.get_default_indicator("260"))
  x260.add_at(MarcNode.new("publication", "a", catalogue["place"], nil), 0 ) if catalogue["place"]
  x260.add_at(MarcNode.new("publication", "c", catalogue["date"], nil), 0 ) if catalogue["date"]
  x260.sort_alphabetically
  new_marc.root.add_at(x260, new_marc.get_insert_position("260") )

  if catalogue["revue_title"] && !catalogue["revue_title"].empty?
    x760 = MarcNode.new("publication", "760", "", mc.get_default_indicator("760"))
    x760.add_at(MarcNode.new("publication", "0", @series_map[catalogue["revue_title"].to_sym], nil), 0 )
    x760.add_at(MarcNode.new("publication", "a", catalogue["revue_title"], nil), 0 )
    x760.sort_alphabetically
    new_marc.root.add_at(x760, new_marc.get_insert_position("760") )
  end

  new_marc.import

  pub = Publication.new
  pub.marc_source = new_marc
  pub.save

end

# Step 1, create new inventories in the Source template

def dexmlize(marc, file)
  doc = REXML::Document.new(File.open("housekeeping/inventories_migration/xml/#{file}"))
  mc = MarcConfigCache.get_configuration("source")

  XPath.each(doc, "/TEI/teiHeader/fileDesc/titleStmt/title") do |txt|
    next if !txt.text || txt.text.strip.empty?
    tag = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
    tag.add_at(MarcNode.new("source", "a", txt.text, nil), 0 )
    tag.sort_alphabetically
    marc.root.add_at(tag, marc.get_insert_position("599") )
  end

  XPath.each(doc, "/TEI/teiHeader/fileDesc/editionStmt/") do |txt|
    #next if !txt.text || txt.text.strip.empty?

    resp_stmt = txt.elements['respStmt']
    concatenated_text = []
    resp_stmt.each_recursive do |element|
      element.text.gsub!("RISM Digital Center", "and RISM Digital Center")
      element.text.gsub!("Swiss RISM Office", "and RISM Digital Center")
      concatenated_text << element.text.strip if element.text
    end

    tag = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
    tag.add_at(MarcNode.new("source", "a", concatenated_text.join(" "), nil), 0 )
    tag.sort_alphabetically
    marc.root.add_at(tag, marc.get_insert_position("599") )
  end

  XPath.each(doc, "/TEI/teiHeader/fileDesc/publicationStmt") do |txt|

    #next if !txt.text || txt.text.strip.empty?

    resp_stmt = txt.elements['publisher']
    concatenated_text = []
    resp_stmt.each_recursive do |element|
      element.text.gsub!("Swiss RISM Office", "RISM Digital Center")
      concatenated_text << element.text.strip if element.text
    end

    concatenated_text << resp_stmt.text.strip if resp_stmt.text

    tag = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
    tag.add_at(MarcNode.new("source", "a", concatenated_text.join(" "), nil), 0 )
    tag.sort_alphabetically
    marc.root.add_at(tag, marc.get_insert_position("599") )
  end

  XPath.each(doc, "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/head") do |head|

    place = head.elements["origPlace"].first
    date = head.elements["origDate"].first rescue date = nil
    title = head.elements["title"].first

    if place || date
      tag = MarcNode.new("source", "260", "", mc.get_default_indicator("260"))
      tag.add_at(MarcNode.new("source", "a", place.to_s, nil), 0 ) if place
      tag.add_at(MarcNode.new("source", "c", date.to_s, nil), 0 ) if date
      tag.add_at(MarcNode.new("source", "8", "01", nil), 0 )
      tag.sort_alphabetically
      marc.root.add_at(tag, marc.get_insert_position("260") )
    end

    if title
      tag = MarcNode.new("source", "245", "", mc.get_default_indicator("245"))
      tag.add_at(MarcNode.new("source", "a", title.to_s, nil), 0 ) if place
      tag.sort_alphabetically
      marc.root.add_at(tag, marc.get_insert_position("245") )
    end

  end

  XPath.each(doc, "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/physDesc/objectDesc/supportDesc/extent") do |txt|
    #next if !txt.text || txt.text.strip.empty?

    pages = txt.elements["measure[@type='pagesCount']"]
    dimensions = txt.elements["measure[@type='pageDimensions']"]

    if pages || dimensions
      tag = MarcNode.new("source", "300", "", mc.get_default_indicator("300"))
      tag.add_at(MarcNode.new("source", "a", pages.text, nil), 0 ) if pages 
      tag.add_at(MarcNode.new("source", "c", dimensions.text, nil), 0 ) if dimensions
      tag.add_at(MarcNode.new("source", "8", "01", nil), 0 )
      tag.sort_alphabetically
      marc.root.add_at(tag, marc.get_insert_position("300") )
    end
  end

  XPath.each(doc, "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/msContents") do |txt|

    tt = txt.elements['summary']
    sanit = tt.inner_text.gsub("\n", " ").strip

    #next if !txt.text || txt.text.strip.empty?
    tag = MarcNode.new("source", "500", "", mc.get_default_indicator("500"))
    tag.add_at(MarcNode.new("source", "a", sanit, nil), 0 )
    tag.sort_alphabetically
    marc.root.add_at(tag, marc.get_insert_position("500") )
  end


  XPath.each(doc, "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/additional/adminInfo/recordHist/source/bibl") do |txt|
    next if !txt.text || txt.text.strip.empty?
    tag = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
    tag.add_at(MarcNode.new("source", "a", txt.text, nil), 0 )
    tag.sort_alphabetically
    marc.root.add_at(tag, marc.get_insert_position("599") )
  end

  XPath.each(doc, "/TEI/teiHeader/fileDesc/sourceDesc/msDesc/additional/listBibl/bibl") do |txt|
    next if !txt.text || txt.text.strip.empty?
    tag = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
    tag.add_at(MarcNode.new("source", "a", txt.text, nil), 0 )
    tag.sort_alphabetically
    marc.root.add_at(tag, marc.get_insert_position("599") )
  end

  tag = MarcNode.new("source", "599", "", mc.get_default_indicator("599"))
  tag.add_at(MarcNode.new("source", "a", file, nil), 0 )
  tag.sort_alphabetically
  marc.root.add_at(tag, marc.get_insert_position("599") )

end

spinner = TTY::Spinner.new("[:spinner] :title", format: :shark)
@inventories_db["libraries"].each do |inventory|

  next if inventory["ext_id"] == 51006873

  spinner.update(title: "Converting #{inventory["name"]}...")
  spinner.auto_spin

  muscat_inventory = Source.new
  muscat_inventory.record_type = MarcSource::RECORD_TYPES[:inventory]
  new_marc = MarcSource.new("=001 __TEMP__", MarcSource::RECORD_TYPES[:inventory])

  mc = MarcConfigCache.get_configuration("source")

  siglum = SIGLUM_MAP[inventory["siglum"].strip.to_sym]
  shelfmark = SHELFMARK_MAP[inventory["siglum"].strip.to_sym]

  # 240 Inventory
  x240 = MarcNode.new("source", "240", "", mc.get_default_indicator("240"))
  x240.add_at(MarcNode.new("source", "0", 3930931, nil), 0 )
  x240.sort_alphabetically
  new_marc.root.add_at(x240, new_marc.get_insert_position("240") )

  # Add Library info
  x852 = MarcNode.new("source", "852", "", mc.get_default_indicator("852"))
  x852.add_at(MarcNode.new("source", "x", siglum, nil), 0 )
  x852.add_at(MarcNode.new("source", "c", shelfmark, nil), 0 )
  x852.sort_alphabetically
  new_marc.root.add_at(x852, new_marc.get_insert_position("852") )

  # WHERE TO PUT THE ADDRESS??
=begin
  if inventory["address"] && !inventory["address"].empty?
    x245 = MarcNode.new("source", "245", "", mc.get_default_indicator("245"))
    x245.add_at(MarcNode.new("source", "a", inventory["address"], nil), 0 )
    x245.sort_alphabetically
    new_marc.root.add_at(x245, new_marc.get_insert_position("245") )
  end
=end

  if inventory["url"] && @manifest_map[inventory["url"].to_sym]
    @manifest_map[inventory["url"].to_sym].each do |mani|
      a856 = MarcNode.new("source", "856", "", mc.get_default_indicator("856"))
      a856.add_at(MarcNode.new("source", "u", "https://iiif.rism.digital/manifest/in/#{mani}", nil), 0 )
      a856.add_at(MarcNode.new("source", "x", "IIIF manifest (digitized source)", nil), 0 )
      a856.add_at(MarcNode.new("source", "z", "IIIF manifest", nil), 0 )
      a856.sort_alphabetically
      new_marc.root.add_at(a856, new_marc.get_insert_position("856") )
    end
  end

  # variant title?
  x246 = MarcNode.new("source", "246", "", mc.get_default_indicator("246"))
  x246.add_at(MarcNode.new("source", "a", inventory["name"], nil), 0 )
  x246.sort_alphabetically
  new_marc.root.add_at(x246, new_marc.get_insert_position("246") )

  # 650 Standard Term
  x650 = MarcNode.new("source", "650", "", mc.get_default_indicator("650"))
  x650.add_at(MarcNode.new("source", "0", 3025686, nil), 0 )
  x650.sort_alphabetically
  new_marc.root.add_at(x650, new_marc.get_insert_position("650") )

  dexmlize(new_marc, inventory["url"]) if inventory["url"] && !inventory["url"].empty?

  new_marc.suppress_scaffold_links
  new_marc.import

  muscat_inventory.marc = new_marc
  muscat_inventory.save
  muscat_inventory.reindex
  
  i2 = Source.find(muscat_inventory.id)
  i2.save

  # Now convert all the inventory_items
  ms2inventory(i2, inventory["id"])

end

Sunspot.commit
puts