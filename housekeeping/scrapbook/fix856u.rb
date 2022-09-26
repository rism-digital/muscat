
count = 0

CSV::foreach("fix856u.csv") do |r|
    s = Source.find(r[0])

    found = false
    s.marc.each_by_tag("856") do |t|

        t.fetch_all_by_tag("u").each do |tn|
          if tn.content.strip == r[1].strip
            xfound = false

            t.fetch_all_by_tag("x").each do |tn|
                xfound = true
            end

            if !xfound
                t.add_at(MarcNode.new("source", "x", r[2], nil), 0)
                t.sort_alphabetically
            end
          end
          found = true
        end
    end

    if !found
        puts "OOPS #{s.id}"
    end

#puts s.marc.to_marc

    s.save
end
