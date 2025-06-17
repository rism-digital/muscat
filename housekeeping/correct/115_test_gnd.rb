items = GND::Interface.search_for_ids({composer: "Bach"}, 10)

items.each do |i|
  marc, xml = GND::Interface.retrieve(i)

  #ap xml

  srw_ns = {'srw' => 'http://www.loc.gov/zing/srw/'}
  marc_ns = {'marc' => 'http://www.loc.gov/MARC21/slim'}
  inner_record = xml.at_xpath('//srw:record//marc:record', srw_ns.merge(marc_ns))

  #ap inner_record

  ap GND::Interface.send_to_gnd(:replace, inner_record, i)
end