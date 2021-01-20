Person.all.each do |p|
    p.referring_sources.each do |s|
        if s.siglum_matches?("CH")
            viaf = ""

            p.marc.each_by_tag("024") do |t|
                a = t.fetch_first_by_tag("2")
                if a && a.content && a.content == "VIAF"
                    b = t.fetch_first_by_tag("a")
                    viaf = b.content if b && b.content
                end
            end

            puts "#{p.full_name}\t#{p.life_dates}\t#{p.id}\t#{viaf}" if !viaf.empty?
            break
        end
    end
end