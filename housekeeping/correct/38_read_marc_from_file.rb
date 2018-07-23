model_name = ARGV[0]
id = ARGV[1]
file = ARGV[2]

puts ARGV.count

if ARGV.count < 3
	puts "Model ID file"
	exit 1
end

if !File.file?(file)
	puts "File #{file} does not exist"
	exit 2
end

puts model_name
puts id
puts file

model = Object.const_get(model_name)

elem = model.find(id)

if elem
	
	elem.marc_source = File.read(file)
	elem.marc.load_source(false)
	elem.marc.import
	
	elem.save
	
end