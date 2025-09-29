def diffize(model, id, marc1, marc2)
  
    lines1 = marc1.split("\n")
    lines2 = marc2.split("\n")

    diffs = Diff::LCS.sdiff(lines1, lines2)

    diffs.each do |diff|
    case diff.action
#    when '='
    when '!'
        #puts "Line #{diff.old_position + 1} changed:"
        puts "#{model}-#{id} ORIG #{diff.old_element}"
        puts "#{model}-#{id} NEW  #{diff.new_element}"
    when '-'
        # Line was removed
        puts "#{model}-#{id} REMOVED #{diff.old_element}"
    when '+'
        # Line was added
        puts "#{model}-#{id} ADDED   #{diff.new_element}"
    end
    end

end

items = GND::Interface.search_for_ids({composer: "Bach"}, 10)

items.each do |i|
  marc, xml = GND::Interface.retrieve(i)
  next if !marc

  marc1 = marc.to_s

  srw_ns = {'srw' => 'http://www.loc.gov/zing/srw/'}
  marc_ns = {'marc' => 'http://www.loc.gov/MARC21/slim'}
  
  # This is not parsed by the Muscat MARC class
  inner_record = xml.at_xpath('//srw:record//marc:record', srw_ns.merge(marc_ns))

  #ap inner_record
  
  # Use the loaded Muscat record
  xml = marc.to_xml({authority: true, force_editor_ordering: false}).gsub('<?xml version="1.0" encoding="UTF-8"?>', '')
  result, messages, author, title = GND::Interface.send_to_gnd(:replace, xml, i)

  if !result
    puts messages
  end

  marc, xml = GND::Interface.retrieve(i)
  marc2 = marc.to_s

  diffize("gnd", i, marc1, marc2)
end