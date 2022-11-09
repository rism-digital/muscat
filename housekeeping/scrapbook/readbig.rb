
works = []
for a in 0..9 do
    works += YAML.load(File.read("big#{a}.yml"))

end

File.open("verybig.yml", "w") { |file| file.write(works.to_yaml) }
