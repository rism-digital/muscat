
cat_a_mapping = Hash.new

cat_a_12 = Hash.new
cat_a_12['gnd'] = ["GerB", "G"]
cat_a_12['bnf'] = ["GerB", "G"]
cat_a_12['mbz'] = ["GerB", "G"]

cat_a_mapping[12] = cat_a_12

File.open( "002-cat-a-mapping.yml" , "w") {|f| f.write(cat_a_mapping.to_yaml) }