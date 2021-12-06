file = ARGV[0]

CSV.foreach(file) do |l|

    s_id = l[0]
    pae_a = l[2].to_s.strip
    pae_b = l[3].to_s.strip
    pae_c = l[4].to_s.strip
    clef = l[5].strip
    key = l[6].strip
    time = l[7].strip
    pae = l[8].strip

    clef_new = l[9].strip
    key_new = l[10].strip
    time_new = l[11].strip
    pae_new = l[12].strip

    next if s_id == "source_id"

    source = Source.find(s_id)

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

            (puts "#{source.id} clef was changed expecting #{clef} is #{vals[:g]}"; next ) if vals[:g] != clef
            (puts "#{source.id} key was changed expecting #{key} is #{vals[:n]}"; next ) if vals[:n] != key
            (puts "#{source.id} time was changed expecting #{time} is #{vals[:o]}"; next ) if vals[:o] != time
            (puts "#{source.id} pae was changed expecting #{pae} is #{vals[:p]}"; next ) if vals[:p] != pae

            
            tags[:g].content = clef_new
            tags[:n].content = key_new
            tags[:o].content = time_new
            tags[:p].content = pae_new

            puts "#{source.id} updated correctly"
        end

    end

    source.save

end