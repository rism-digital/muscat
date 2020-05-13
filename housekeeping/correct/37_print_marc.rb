model_name = ARGV[0]
id = ARGV[1]

if ARGV.count < 2
	puts "Model ID"
	exit 1
end

model = Object.const_get(model_name)

elem = model.find(id)
puts elem.marc_source