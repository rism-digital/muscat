# first argument is the file containing marc records
# second is the model name
# third is the offset to start from

PaperTrail.request.disable_model(Catalogue)
PaperTrail.request.disable_model(Holding)
PaperTrail.request.disable_model(Institution)
PaperTrail.request.disable_model(Person)
PaperTrail.request.disable_model(Source)

if ARGV.length >= 2
  source_file = ARGV[0]
  model = ARGV[1]
  from = 0
  from = ARGV[2] if ARGV[2]
  if File.exists?(source_file)
    import = MarcImport.new(source_file, model, from.to_i)
    import.import
    $stderr.puts "\nCompleted: "  +Time.new.strftime("%Y-%m-%d %H:%M:%S")
  else
    puts source_file + " is not a file!"
  end
else
  puts "Bad arguments, specify marc file and model class to use"
end
