require 'progress_bar'

puts "Fixing Person"
pb = ProgressBar.new(Person.count)
Person.all.each do |p|
  c = p.referring_sources.count
  p.suppress_reindex
  p.update_attribute( :src_count, c ) if c != p.src_count
  pb.increment!
end

puts "Fixing Standard Title"
pb = ProgressBar.new(StandardTitle.count)
StandardTitle.all.each do |s|
  c = s.referring_sources.count
  s.update_attribute( :src_count, c ) if c != s.src_count
  pb.increment!
end

puts "Fixing Standard Term"
pb = ProgressBar.new(StandardTerm.count)
StandardTerm.all.each do |st|
  c = st.referring_sources.count
  st.update_attribute( :src_count, c ) if c != st.src_count
  pb.increment!
end

puts "Fixing Publication"
pb = ProgressBar.new(Publication.count)
Publication.all.each do |c|
  cs = c.referring_sources.count
  c.update_attribute( :src_count, cs ) if cs != c.src_count
  pb.increment!
end

puts "Fixing Liturgical Feast"
pb = ProgressBar.new(LiturgicalFeast.count)
LiturgicalFeast.all.each do |l|
  c = l.referring_sources.count
  l.update_attribute( :src_count, c ) if c != l.src_count
  pb.increment!
end

puts "Fixing Place"
pb = ProgressBar.new(Place.count + 1) #can be zero!
Place.all.each do |p|
  c = p.referring_sources.count
  p.update_attribute( :src_count, c ) if c != p.src_count
  pb.increment!
end

puts "Fixing Institution"
pb = ProgressBar.new(Institution.count)
Institution.all.each do |i|
  c = i.referring_sources.count
  i.update_attribute( :src_count, c ) if c != i.src_count
  pb.increment!
end
