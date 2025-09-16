def update_record(all_records)
  # Fine the record that has the RISM ID
  # And add to that
  rism_id = nil
  corago_ids = all_records.map{|r| r["COD_RESP0"]; rism_id = r["ID_RISM"].to_i if r["ID_RISM"] }

  ap rism_id

end

corago = Roo::Spreadsheet.open("Corago-ization.ods")

corago.default_sheet = corago.sheets.first

rows = corago.sheet(0).parse(headers: true)

grouped = rows.group_by { |r| r["COD_RESP0"].to_s.strip }  # => { "123" => [row1, row2, ...], "456" => [...] }

# Example: iterate groups
grouped.each do |resp_id, records|
  puts "ID #{resp_id}: #{records.size} rows"
  
  action = :update

  # One of the records contains the action to do...
  records.each do |row|
    # "x" means this was checked
    if row["CHK_IDRISM"] == "x"
      # RISM id present? update existing record
      # Or else switch to the create option
      if row["ID_RISM"] == nil
        action = :create
      end

    elsif row["CHK_IDRISM"] == "ToMatch"
      action = :match
    end
  end

  if action == :create
    puts "Add #{resp_id}..."
  elsif action == :update
    puts "Update RISM record"
    update_record(records)
  else
    # skip for now
  end

end