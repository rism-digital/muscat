Work.all.each do |s|
    s.marc.load_source false
    s.marc.import
    s.save
end