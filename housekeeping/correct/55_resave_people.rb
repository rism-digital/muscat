c = Person.where("marc_source LIKE ?", "%=551%").count

pb = ProgressBar.new(Person.all.count)

Person.where("marc_source LIKE ?", "%=551%").each do |p|
    pe = Person.find(p.id)

    pe.marc.load_source false
    pe.marc.import
    PaperTrail.request(enabled: false) do
        pe.save
    end

    #ap pe.id
    pb.increment!
end