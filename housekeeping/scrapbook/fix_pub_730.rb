Publication.all.each do |p|
    mod = false

    s.marc.each_by_tag("730") do |t|
        t.tag = "246"
        mod = true
    end

    p.save if mod
end