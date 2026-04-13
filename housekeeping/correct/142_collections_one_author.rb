Source.where(record_type: 1).where.not("marc_source LIKE ?", "%=100%").each do |s|

  found = false

  s.marc.load_source false
  s.marc["593"].each do |t|
    t["a"].each do |tt|
      found = true if tt.content == "Autograph manuscript"
    end
  end

  next if !found

  cmp = s.child_sources.map {|cs| cs.composer}.sort.uniq

  if cmp.count == 1
    puts [s.id, s.composer, cmp.first].join("\t")
  end

end