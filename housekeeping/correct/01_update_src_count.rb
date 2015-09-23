ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count Person") {
    Person.all.each do |p|
      c = p.sources.count
      p.suppress_reindex
      p.update_attribute( :src_count, c ) if c != p.src_count
    end
  }
  end
end

ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count StandardTitle") { 
    StandardTitle.all.each do |s|
      c = s.sources.count
      s.update_attribute( :src_count, c ) if c != s.src_count
    end
  }  
  end
end

ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count StandardTerm") {
    StandardTerm.all.each do |st|
      c = st.sources.count
      st.update_attribute( :src_count, c ) if c != st.src_count
    end
  }
  end
end

ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count Catalogue") { 
    Catalogue.all.each do |c|
      cs = c.sources.count
      c.update_attribute( :src_count, cs ) if cs != c.src_count
    end
  }
  end
end
 
ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count LiturgicalFeasts") {   
    LiturgicalFeast.all.each do |l|
      c = l.sources.count
      l.update_attribute( :src_count, c ) if c != l.src_count
    end
  }
  end
end
 
ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count Place") { 
    Place.all.each do |p|
      c = p.sources.count
      p.update_attribute( :src_count, c ) if c != p.src_count
    end
  }
  end
end

ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count Institution") {
    Institution.all.each do |i|
      c = i.sources.count
      i.update_attribute( :src_count, c ) if c != i.src_count
    end
  }
  end
end

ActiveRecord::Base.transaction do
  Benchmark.bm(7) do |x| x.report("Count Library") {
    Library.all.each do |l|
      c = l.sources.count
      l.update_attribute( :src_count, c ) if c != l.src_count
    end
  }
  end
end