def extract_number(line)
  numish = line[/\bNr\.?\s*([0-9A-Za-z]+(?:[.,][0-9A-Za-z]+)*)/i, 1] ||
           line[/[0-9][0-9A-Za-z]*(?:[.,][0-9A-Za-z]+)*/]
  numish&.gsub(/[A-Za-z]/, '')
end

Source.where(record_type: [12, 13]).each do |s|
  
=begin
  puts "Magic being applied to #{s.id}"
  s.inventory_items.each do |ii|
    #number = ii.page_info[/[0-9A-Za-z]+(?:[.,][0-9A-Za-z]+)*/]&.gsub(/[A-Za-z]/, '')
    number = extract_number(ii.page_info)
    #puts "#{ii.source_id}\t#{ii.page_info}\t\t#{number}"

    # try to split. if not splittable, returns the whole nr
    parts = number.split(".")
    parts = number.split(".") if number.include?(",")
    high = parts[0].to_i * 100
    low = parts.count > 1 ? parts[1].to_i : 0

    ii.update_column(:source_order, high + low)
  end
=end
  # Now set a sane number
  puts "Now set a sane number to #{s.id}"
  s.inventory_items.order(id: :asc).each.with_index do |ii, idx|
    #puts "#{ii.id} #{idx}"
    ii.update_column(:source_order, idx)
  end

end


=begin
    if [1001320388, 1001316763, 1001316759, 1001316757, 
        1001316756, 1001316755, 1001316753, 1001316752, 1001316752,1001316751].include? ii.source_id
      
      # easy peasy
      ii.source_order = number.to_i
    elsif ii.source_id == 1001316762
      # 1001316762 mix XXX XXX.YY
      
      parts = number.split(".")
      high = parts[0].to_i * 100
      low = parts.count > 1 ? parts[1].to_i : 0

      ii.source_order = high + low

    elsif ii.source_id == 1001316758
      # 1001316758 XX,YY or X,X
      parts = number.split(",")
      high = parts[0].to_i * 100
      low = parts.count > 1 ? parts[1].to_i : 0
      
      ii.source_order = high + low

    elsif ii.source_id == 1001316754
        # 1001316754 XX or XX.Y
    elsif ii.source_id == 1001316750
      # 1001316750 XXX.YY
    end
=end


  # 1001320388 Nr. 
  # 1001316763 XXX
  # 1001316759 XXX

  # 1001316757, 1001316756, 1001316755, 1001316753, 1001316752 XX
  # 1001316752 XXX
  # 1001316751 XXX
  # 1001316750 XXX.YY