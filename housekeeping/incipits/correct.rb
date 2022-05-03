file = ARGV[0]

CSV.foreach(file) do |l|

    s_id = l[0]
    pae_a = l[2].to_s.strip
    pae_b = l[3].to_s.strip
    pae_c = l[4].to_s.strip
    clef = l[6].strip
    key = l[7].strip
    time = l[8].strip
    pae = l[9].strip

    clef_new = l[10].strip
    key_new = l[11].strip
    time_new = l[12].strip
    pae_new = l[13].strip
    note = l[14].strip

    next if s_id == "source_id"

    begin
        source = Source.find(s_id)
    rescue ActiveRecord::RecordNotFound
        puts "Source #{s_id} was deleted".red
        next
    end

    subtags = [:a, :b, :c, :g, :n, :o, :p]
    vals = {}
    tags = {}
    
    source.marc.load_source true
    source.marc.each_by_tag("031") do |t|

        subtags.each do |st|
            v = t.fetch_first_by_tag(st)
            vals[st] = v && v.content ? v.content : nil
            tags[st] = v
        end

        if pae_a == vals[:a] && pae_b == vals[:b] && pae_c == vals[:c]

            #puts "updating #{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]}"

            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} clef was changed expecting #{clef} is #{vals[:g]}"; next ) if vals[:g] != nil && vals[:g].strip != clef.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} key was changed expecting #{key} is #{vals[:n]}"; next ) if vals[:n] != nil && vals[:n].strip != key.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} time was changed expecting #{time} is #{vals[:o]}"; next ) if vals[:o] != nil && vals[:o].strip != time.strip
            (puts "#{source.id} #{vals[:a]}.#{vals[:b]}.#{vals[:c]} pae was changed expecting #{pae} is #{vals[:p]}"; next ) if vals[:p] != nil && vals[:p].strip != pae.strip

            tags[:g].content = clef_new.strip if !clef_new.empty?
            tags[:n].content = key_new.strip if !key_new.empty?
            tags[:o].content = time_new.strip if !time_new.empty? || time_new.strip != vals[:o].strip
            tags[:p].content = pae_new.strip if !pae_new.empty?

            if !note.empty?
                t.add_at(MarcNode.new("source", "q", note, nil), 0)
                t.sort_alphabetically
            end
            
        end

    end

    source.save

end