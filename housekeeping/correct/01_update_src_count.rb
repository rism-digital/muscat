
Benchmark.bm(7) do |x| x.report("Count Person") {
  Person.all.each do |p|
    p.update_attribute( :src_count, p.sources.count )
  end
}
end

Benchmark.bm(7) do |x| x.report("Count StandardTitle") { 
  StandardTitle.all.each do |s|
    s.update_attribute( :src_count, s.sources.count )
  end
}  
end

Benchmark.bm(7) do |x| x.report("Count StandardTerm") {
  StandardTerm.all.each do |st|
    st.update_attribute( :src_count, st.sources.count )
  end
}
end

Benchmark.bm(7) do |x| x.report("Count Catalogue") { 
  Catalogue.all.each do |c|
    c.update_attribute( :src_count, c.sources.count )
  end
}
end
 
Benchmark.bm(7) do |x| x.report("Count LiturgicalFeasts") {   
  LiturgicalFeast.all.each do |l|
    l.update_attribute( :src_count, l.sources.count )
  end
}
end
 
Benchmark.bm(7) do |x| x.report("Count Place") { 
  Place.all.each do |p|
    p.update_attribute( :src_count, p.sources.count )
  end
}
end

Benchmark.bm(7) do |x| x.report("Count Institution") {
  Institution.all.each do |i|
    i.update_attribute( :src_count, i.sources.count )
  end
}
end

Benchmark.bm(7) do |x| x.report("Count Library") {
  Library.all.each do |l|
    l.update_attribute( :src_count, l.sources.count )
  end
}
end
