def get_pae_tag(marc, index)

    numbers = index.split(".")

    marc.each_by_tag("031") do |node|
        a = node.fetch_first_by_tag("a").content.strip
        b = node.fetch_first_by_tag("b").content.strip
        c = node.fetch_first_by_tag("c").content.strip

        if a == numbers[0] && b == numbers[1] && c == numbers[2]
            return node
        end
    end

    nil
end

def file_to_lines(filename)
    result = {}
    File.open(filename, "r") do |f|
        f.each_line do |line|
            if line.starts_with?("@clef")
                data = line.gsub!("@clef:", "")
                result[:clef] = data.strip
            elsif line.starts_with?("@keysig")
                data = line.gsub!("@keysig:", "")
                result[:key] = data.strip
            elsif line.starts_with?("@timesig")
                data = line.gsub!("@timesig:", "")
                result[:time] = data.strip
            elsif line.starts_with?("@data")
                data = line.gsub!("@data:", "")
                result[:pae] = data.strip
            end
        end
    end

    result
end

CSV::foreach("05-1752-incipits-mapping-final.csv") do |line|

    file = line[0].strip.gsub(".pae", "")
    id = line[1].strip
    nr = line[2].strip

    source = Source.find(id)
puts id
    node = get_pae_tag(source.marc, nr)

    if !node
        puts "Not found #{id} #{nr}"
        next
    end

    pae = file_to_lines("musicat_incipits/PAE/" + file + ".pae")

    begin
        node.fetch_first_by_tag("p").content = pae[:pae]
    rescue NoMethodError
        node.add_at(MarcNode.new("source", "p", pae[:pae], nil), 0 )
    end

    begin
        node.fetch_first_by_tag("n").content = pae[:key]
    rescue NoMethodError
        node.add_at(MarcNode.new("source", "n", pae[:key], nil), 0 )
    end

    begin
        node.fetch_first_by_tag("g").content = pae[:clef]
    rescue NoMethodError
        node.add_at(MarcNode.new("source", "g", pae[:clef], nil), 0 )
    end
    
    begin
        node.fetch_first_by_tag("o").content = pae[:time]
    rescue NoMethodError
        node.add_at(MarcNode.new("source", "o", pae[:time], nil), 0 )
    end

    node.sort_alphabetically

    source.save


    obj = DigitalObject.create(:attachment => File.open("musicat_incipits/MEI/" + file + ".mei", 'rb'), :description => "#{source.id}:#{nr}")
    dol = DigitalObjectLink.create(object_link_type: "Source", object_link_id: source.id, user: source.user, digital_object_id: obj.id)
end