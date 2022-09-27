# first argument is the file containing marc records
# second is the model name
# third is the offset to start from

valid_models = ["Source", "Publication", "Holding", "Person", "Institution",
                "Work"]
valid_models.each do |model|
  PaperTrail.request.disable_model(model.constantize)
end

if ARGV.length >= 2
  source_file = ARGV[0]
  model = ARGV[1]
  from = 0
  from = ARGV[2] if ARGV[2]
  if ! valid_models.include? model
    $stderr.puts "Invalid record type. Valid models are: " + valid_models.join(', ')
  elsif File.exists?(source_file)
    import = MarcImport.new(source_file, model, from.to_i)
    import.import
    $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
  else
    $stderr.puts source_file + " is not a file!"
  end
else
  $stderr.puts "Bad arguments, specify marc file and model class to use"
end
