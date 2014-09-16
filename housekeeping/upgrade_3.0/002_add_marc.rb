# After the update the People marc data is not populated
# Use this script to fill it with a basic marc record.

Person.find_each do |p|
  p.scaffold_marc
  p.save
  puts "Saved #{p.id}"
end