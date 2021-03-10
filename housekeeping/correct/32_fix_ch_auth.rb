require 'progress_bar'
=begin
pb = ProgressBar.new(Publication.all.count)

Publication.all.each do |c|

  pb.increment!

  m = MarcPublication.new(c.marc_source)
  m.load_source(false)
  m.import
  c.marc = m
  c.save
end
=end

pb = ProgressBar.new(Person.all.count)

Person.all.each do |c|

  pb.increment!

  m = MarcPerson.new(c.marc_source)
  m.load_source(false)
  m.import
  c.marc = m
  c.save
end