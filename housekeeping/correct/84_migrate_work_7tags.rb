Work.all.each do |w|
    # is this too evil?
    r1 = w.marc_source.gsub!("=700", "=500")
    r2 = w.marc_source.gsub!("=710", "=510")
    r3 = w.marc_source.gsub!("=747", "=547")

    w.save if r1 || r2 || r3
end