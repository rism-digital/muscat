def each_record(filename, &block)
  File.open(filename) do |file|
    Nokogiri::XML::Reader.from_io(file).each do |node|
      if node.name == 'record' and node.node_type == Nokogiri::XML::Reader::TYPE_ELEMENT
        yield(Nokogiri::XML(node.outer_xml).root)
      end
    end
  end
end

NAMESPACE={'marc' => "http://www.loc.gov/MARC21/slim"}
classes = %w(Latin LiturgicalFeast Place StandardTerm)

if ARGV.length >= 1
  source_file = ARGV[0]
  if File.exists?(source_file)
    each_record(source_file) { |record|
      next if record.xpath("//marc:datafield[@tag='750']/marc:subfield[@code='a']", NAMESPACE).first
      if class_name = record.xpath("//marc:datafield[@tag='336']/marc:subfield[@code='a']", NAMESPACE).first
        next unless classes.include?(class_name.text)
        puts class_name.text
        name = record.xpath("//marc:datafield[@tag='150']/marc:subfield[@code='a']", NAMESPACE).first.text
        id = record.xpath("//marc:controlfield[@tag='001']", NAMESPACE).first.text.to_i
        existing =  Object.const_get(class_name.text).where(:name => name)
        binding.pry unless Object.const_get(class_name.text).where(:id => id).empty?
        thes = !existing.empty? ? existing.first : Object.const_get(class_name.text).new
        thes.name = name if existing.empty?
        # thes.name.gsub!(", ", " | ") if class_name.text == 'Latin'
        thes.id = id
        if alternate_terms = record.xpath("//marc:datafield[@tag='550']/marc:subfield[@code='a']", NAMESPACE)
          thes.alternate_terms = alternate_terms.map{|n| n.content}.join("\n")
          # thes.alternate_terms.gsub!(", ", " | ") if class_name.text == 'Latin'
        end
        if sub_topics = record.xpath("//marc:datafield[@tag='780']/marc:subfield[@code='a']", NAMESPACE)
          thes.sub_topic = sub_topics.map{|n| n.content}.join("\n")
          # thes.sub_topic.gsub!(", ", " | ") if class_name.text == 'Latin'
        end
        if notes = record.xpath("//marc:datafield[@tag='680']/marc:subfield[@code='a']", NAMESPACE)
          thes.notes = notes.map{|n| n.content}.join("\n")
        end
        thes.save
      end

    }
    $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
  else
    puts source_file + " is not a file!"
  end
else
  puts "Bad arguments, specify marc file and model class to use"
end

