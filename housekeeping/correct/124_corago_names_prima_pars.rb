@mc = MarcConfigCache.get_configuration("person")

@the_map = {
  "40221058": 30031214 # Ganbuzzi Innocenzo
}

def update_record(all_records)
  # Fine the record that has the RISM ID
  # And add to that
  #rism_id = nil
  #corago_ids = all_records.map{|r| r["COD_RESP0"]; rism_id = r["ID_RISM"].to_i if r["ID_RISM"] }

  idx = all_records.index { |h| h["CHK_IDRISM"] == "x" }
  principal_entry = all_records.delete_at(idx) if idx

  id = @the_map[principal_entry["ID_RISM"].to_sym] ||
        principal_entry["ID_RISM"].to_i

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

    puts "Add #{fullname} to #{p.id}" if !found

    a400 = MarcNode.new("person", "400", "", @mc.get_default_indicator("400"))
    a400.add_at(MarcNode.new("person", "j", "xx", nil), 0 )
    a400.add_at(MarcNode.new("person", "a", fullname, nil), 0 )
    a400.sort_alphabetically
    p.marc.root.add_at(a400, p.marc.get_insert_position("400") )
  end

  p.paper_trail_event = "Add CORAGO ID #{principal_entry["COD_RESP"]}"
  p.save

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
  elsif action == :update
    #puts "Update RISM record"
    update_record(records)
  else
    # skip for now
  end

end