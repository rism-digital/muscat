s1 = Source.find(ARGV[0])
s2 = Source.find(ARGV[1])

s1.marc["031"].each do |t|
  ap t["b"]&.first&.content&.to_i
  ap t["b"]&.first&.content&.to_i <= 15
  next if t["b"]&.first&.content&.to_i <= 15

  s2.marc.root.add_at(t.deep_copy, s2.marc.get_insert_position("031") )

end

puts s2.marc
s2.save