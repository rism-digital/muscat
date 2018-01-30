FILENAME = "zrpeople.yml"
h = {}
Person.all.each {|pr| h[pr.id] = pr.full_name}
File.open(FILENAME, "w") {|f| f.write h.to_yaml}