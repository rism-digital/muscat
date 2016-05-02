a = []
c = []
e = []

pb = ProgressBar.new(Source.all.count)

Source.all.each do |source|
  
  marc = source.marc
  marc.load_source
    
  marc.each_by_tag("541") do |t|
    
    ta = t.fetch_first_by_tag("a")
    tc = t.fetch_first_by_tag("c")
    te = t.fetch_first_by_tag("e")
    
    a << ta.content if ta && ta.content
    c << tc.content if tc && tc.content
    e << te.content if te && te.content
  end
  
  pb.increment!
  
end

puts ta.sort.uniq
