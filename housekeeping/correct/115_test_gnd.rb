items = GND::Interface.search_for_ids({composer: "Bach"}, 10)

items.each do |i|
  marc, xml = GND::Interface.retrieve(i)
  next if !marc

  srw_ns = {'srw' => 'http://www.loc.gov/zing/srw/'}
  marc_ns = {'marc' => 'http://www.loc.gov/MARC21/slim'}
  
  # THis is not parsed by the Muscat MARC class
  inner_record = xml.at_xpath('//srw:record//marc:record', srw_ns.merge(marc_ns))

  #ap inner_record
  
  # Use the loaded Muscat record
  xml = marc.to_xml({authority: true, force_editor_ordering: false}).gsub('<?xml version="1.0" encoding="UTF-8"?>', '')
  result, messages, author, title = GND::Interface.send_to_gnd(:replace, xml, i)

  if !result
    puts messages
  end
end