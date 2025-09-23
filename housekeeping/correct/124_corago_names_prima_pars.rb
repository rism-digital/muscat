# Augh maximus
unless Marc.instance_methods.include?(:insert)
  module MarcInsertBackportInstance
    def insert(tag, subtags = {})
      the_t = MarcNode.new(@model, tag, "", @marc_configuration.get_default_indicator(tag))

      subtags.each do |stag, val|
        next if !val
        next if val.empty?
        the_t.add_at(MarcNode.new(@model, stag.to_s, val, nil), 0 )
      end

      the_t.sort_alphabetically
      @root.add_at(the_t, get_insert_position(tag))
      return the_t
    end
  end

  Marc.prepend(MarcInsertBackportInstance)
end

@mc = MarcConfigCache.get_configuration("person")

@the_map = {
  "40221058": 30031214 # Ganbuzzi Innocenzo
}

@the_place_map = {
  "Strasburgo": "Strasburg",
  "Alessandria d'Egitto": "Alexandria",
  "Novellara, Reggio nell'Emilia": "Novellara",
  "Kensington, London": "Kensington",
  "Bertinoro (Forlì)": "Bertinoro"
}

def update_record(all_records, found_id = nil)
  # Fine the record that has the RISM ID
  # And add to that
  #rism_id = nil
  #corago_ids = all_records.map{|r| r["COD_RESP0"]; rism_id = r["ID_RISM"].to_i if r["ID_RISM"] }

  if found_id
    idx = all_records.index { |h| h["COD_RESP"].end_with? "0" }
  else
    idx = all_records.index { |h| h["CHK_IDRISM"] == "x" }
  end
  
  principal_entry = all_records.delete_at(idx) if idx

  if found_id
    id = found_id
  else
    id = @the_map[principal_entry["ID_RISM"].to_sym] || principal_entry["ID_RISM"].to_i
  end

  p = Person.find(id)

  # Add the link to the CORAGO principal entry
  a024 = MarcNode.new("person", "024", "", @mc.get_default_indicator("024"))
  a024.add_at(MarcNode.new("person", "2", "CORAGO", nil), 0 )
  a024.add_at(MarcNode.new("person", "a", principal_entry["COD_RESP"], nil), 0 )
  a024.sort_alphabetically
  p.marc.root.add_at(a024, p.marc.get_insert_position("024") )

  # Do we have more items left? Add 400s!
  all_records.each do |r|
    
    fullname = [r["COGNOME"]&.strip, r["NOME"]&.strip].compact.join(", ")
    fullname = "#{fullname} #{r["PREFISSO"]&.strip}" if r["PREFISSO"]
    
    found = false
    p.marc["400"].each do |t|
      found = true if t["a"].first.content.strip.downcase == fullname.downcase
    end

    puts "Add variant #{fullname} to #{p.id}" if !found

    p.marc.insert("400", a: fullname, j: "xx")
  end

  p.paper_trail_event = "Add CORAGO ID #{principal_entry["COD_RESP"]}"
  p.save

end

def create_record(records)

  idx = records.index { |h| h["CHK_IDRISM"] == "x" }
  principal_entry = records.delete_at(idx) if idx

  person = Person.new

  new_marc = MarcPerson.new("=001 __TEMP__\n")
  new_marc.load_source false
  person.marc = new_marc


  new_marc.insert("040", a: "DE-633", b: "ita", c: "DE-633", e: "rismg")
  new_marc.insert("024", a: principal_entry["COD_RESP"], "2": "CORAGO")

  fullname = [principal_entry["COGNOME"]&.strip, principal_entry["NOME"]&.strip].compact.join(", ")
  fullname = "#{fullname} #{principal_entry["PREFISSO"]&.strip}" if principal_entry["PREFISSO"]

  year_a = principal_entry["DATA_NAS_IND"]&.split("/")&.first
  year_b = principal_entry["DATA_MOR_IND"]&.split("/")&.first
  years = [year_a, year_b].compact.join("-")

  years_free = [principal_entry["DATA_NAS_LIBERA"], principal_entry["DATA_MOR_LIBERA"]].compact.join("-")

  new_marc.insert("100", a: fullname, d: years, y: years_free)

  if principal_entry["LOC_NAS_R"]
    loc = principal_entry["LOC_NAS_R"].strip
    plz = @the_place_map.fetch(loc.to_sym, loc)
    if plz.include?("?")
      new_marc.insert("680", a: plz)
    else
      new_marc.insert("551", a: plz, i: "go")
    end
  end

  if principal_entry["LOC_MOR_R"]
    loc = principal_entry["LOC_MOR_R"].strip
    plz = @the_place_map.fetch(loc.to_sym, loc)
    if plz.include?("?")
      new_marc.insert("680", a: plz)
    else
      new_marc.insert("551", a: principal_entry["LOC_MOR_R"].strip, i: "so")
    end
  end

  if principal_entry["NOTE_WEB"]
    new_marc.insert("680", a: principal_entry["NOTE_WEB"].strip)
  end

  if principal_entry["BIOGRAFIA"]
    new_marc.insert("680", a: principal_entry["BIOGRAFIA"].strip)
  end

 records.each do |r|
    fullname = [r["COGNOME"]&.strip, r["NOME"]&.strip].compact.join(", ")
    fullname = "#{fullname} #{r["PREFISSO"]&.strip}" if r["PREFISSO"]
    
    new_marc.insert("400", a: fullname, j: "xx")
  end

  #ap Date.parse(principal_entry["DATA_NAS_IND"])

  puts new_marc

  new_marc.import
  person.save
  puts person.id

  person.index

end

def match_test(records)
  all_recs = records.dup
  idx = records.index { |h| h["COD_RESP"].end_with? "0" }
  r = records.delete_at(idx) if idx
  name = [r["COGNOME"]&.strip, r["NOME"]&.strip].compact.join(", ")
  name = "#{name} #{r["PREFISSO"]&.strip}" if r["PREFISSO"]

  #exact_matches = {}
  maybe_matches = {}
  not_found = []

  prs = Person.where(full_name: name)
  if prs.count > 0
      prs.each do |pr|
          #puts "#{pr.id} #{name}"
          #exact_matches[name] ||= Array.new
          #exact_matches[name] << {muscat_id: pr.id, muscat_name: pr.full_name, corago_name: name}
          puts "#{name} maps to #{pr.id}"
          update_record(all_recs.dup, pr.id)
      end
  else

      res = Person.solr_search do
          adjust_solr_params do |p|
              p["q.op"] = "AND"
            end
          fulltext name, :fields => [:full_name,  :"400a"]
          #fulltext sanit_name, :fields => :"400a"
          #with "full_name_or_400a", sanit_name
      end

      if res.results.count > 0
          #puts name.yellow
          res.results.each do |pp|
              #puts pp.full_name.green
              maybe_matches[name] ||= Array.new
              maybe_matches[name] << {muscat_id: pp.id, muscat_name: pp.full_name}
          end
      else
          not_found << name
      end
      sleep(0.005)
  end

  #ap exact_matches
end

corago = Roo::Spreadsheet.open("Corago-ization.ods")

corago.default_sheet = corago.sheets.first

rows = corago.sheet(0).parse(headers: true)

grouped = rows.group_by { |r| r["COD_RESP0"].to_s.strip }  # => { "123" => [row1, row2, ...], "456" => [...] }

# Example: iterate groups
grouped.each do |resp_id, records|
  next if resp_id == "COD_RESP0" # d'oh
  #puts "ID #{resp_id}: #{records.size} rows"
  
  action = :none

  # One of the records contains the action to do...
  records.each do |row|
    # "x" means this was checked
    if row["CHK_IDRISM"] == "x"
      # RISM id present? update existing record
      # Or else switch to the create option
      if row["ID_RISM"] == nil
        action = :create
      else
        action = :update
      end

    elsif row["CHK_IDRISM"] == "ToMatch"
      action = :match
    end
  end

  if action == :create
    #puts "Add #{resp_id}..."
    #create_record(records)
  elsif action == :update
    #puts "Update RISM record"
    #update_record(records)
  elsif action == :match
    match_test(records)
  else
    # skip for now
  end

end

Sunspot.commit