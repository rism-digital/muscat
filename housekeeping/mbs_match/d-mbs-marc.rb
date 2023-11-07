NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim", 'srw' => "http://www.loc.gov/zing/srw/", 'diag' => "http://www.loc.gov/zing/srw/diagnostic/", 'ucp' => "http://www.loc.gov/zing/srw/update/"}

data = YAML::load(File.read("dnb_marc.yml"))

data.each do |id, rec|
    xml = Nokogiri::XML(rec)

    xml.xpath("//marc:record", NAMESPACE).each do |record|
        marc = MarcSource.new()
        marc.load_from_xml(record)
        ap marc
    end
end