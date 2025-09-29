all = []
pb = ProgressBar.new(Person.all.count)
Person.all.each do |s|
    mod = false
    s.marc.load_source false

    s.marc.each_by_tag("042") do |t|
        tgs = t.fetch_first_by_tag("a")
        tgs&.content = "undifferentiated" if tgs&.content == "not individualized"
        tgs&.content = "differentiated" if tgs&.content == "individualized"
        mod = true
    end

    PaperTrail.request(enabled: false) do
        s.save if mod
    end
    pb.increment!
end
