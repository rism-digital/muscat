def are_all_children_auth?(child_sources)
  child_sources.all? do |s|
    s.marc.load_source false

    s.marc["593"].any? do |t|
      t["a"].any? { |tt| tt.content == "Autograph manuscript" }
    end
  end
end

def at_least_one_child_auth?(child_sources)
  child_sources.any? do |s|
    s.marc.load_source false

    Array(s.marc["593"]).any? do |t|
      Array(t["a"]).any? { |tt| tt.content == "Autograph manuscript" }
    end
  end
end

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

  if cmp.count == 1 && are_all_children_auth?(s.child_sources)
    puts [s.id, s.lib_siglum, cmp.first].join("\t")
  end

end