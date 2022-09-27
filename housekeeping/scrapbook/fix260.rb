
count = 0

CSV::foreach("fix260.csv") do |r|
    s = Source.find(r[0])
    count += 1

    countb = 0
    s.marc.each_by_tag("260") do |t|
        found = false
        t.fetch_all_by_tag("c").each do |tn|
          found = true
        end

        if !found     
            t.add_at(MarcNode.new("source", "c", r[1], nil), 0)
            t.sort_alphabetically
        end
    end

    s.save
end
