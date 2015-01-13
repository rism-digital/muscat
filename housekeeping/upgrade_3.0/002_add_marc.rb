# After the update the People marc data is not populated
# Use this script to fill it with a basic marc record.

# 50000000 is the offset for locally generated data
# The others are sync'd with RISM auth files

#Person.where("id >= 50000000" ).find_each do |p|
#  p.scaffold_marc
#  p.save
#  puts "Saved #{p.id}"
#end

Institution.where("id >= 50000000" ).find_each do |p|
  puts "Saving #{p.id}"
  p.scaffold_marc
  p.save
end