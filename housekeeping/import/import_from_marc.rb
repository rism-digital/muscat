# Import Marcxml records into Muscat database
# Run as bin/rails runner housekeeping/import/import_from_marc.rb

VALID_MODELS = ["Source", "Publication", "Holding", "Person", "Institution",
                "Work"]

def display_help
  script = "bin/rails runner #{$0}"
  valid_models_list = VALID_MODELS.join(', ')
  puts "Import marcxml records into Muscat database

Usage:  #{script} [options]

Options:
 -f, --file        input file name, required
 -t, --type        record type; choose one of: #{valid_models_list}
 -m, --from        first record to import
 -v, --versioning  update records version
 -u, --authorities create (scaffold) related Marc authorities records
 -i, --insert      only add new records, skip duplicates [NOT YET IMPLEMENTED]
 -r, --replace     only overwrite existing records, skip new ones [NOT YET]
 -a, --append      only append non-existing tags to existing records [NOT YET]
 -n, --dry-run     only simulate, do not update database
 -h, --help        this help

This script can also be run with positional arguments:

 #{script} filename type [from]
"
  exit false
end


runs_under_rails = Rails.initialized? rescue nil
if ! runs_under_rails then
  $stderr.puts "This script has to be run under Rails"
  display_help
end

source_file = nil
model = nil
options = {
  from: 0,
  versioning: false,
  scaffold: false,
  insert: false,
  replace: false,
  append: false,
  dry_run: false,
}

while ARGV.any? do
  arg = ARGV.shift
  if ["-f", "--file"].include? arg
    if ARGV.any? then
      arg = ARGV.shift
      if File.exists? arg then
        source_file = arg
      else
        $stderr.puts "#{arg} is not a file!"
        exit false
      end
    end
  elsif ["-t", "--type"].include? arg
    if ARGV.any? then
      arg = ARGV.shift
      if VALID_MODELS.include? arg
        model = arg
      else
        $stderr.puts "Invalid record type: #{arg}\nValid values are: " + VALID_MODELS.join(', ')
        exit false
      end
    end
  elsif ["-m", "--from"].include? arg
    if ARGV.any? then
      arg = ARGV.shift
      if Integer(arg, exception: false)
        options[:from] = arg.to_i
      else
        $stderr.puts "Non-numeric argument: #{arg}"
        exit false
      end
    end
  elsif ["-v", "--versioning"].include? arg
    options[:versioning] = true
  elsif ["-a", "--authorities"].include? arg
    options[:authorities] = true
  elsif ["-r", "--replace"].include? arg
    options[:replace] = true
  elsif ["-i", "--insert"].include? arg
    options[:insert] = true
  elsif ["-a", "--append"].include? arg
    options[:append] = true
  elsif ["-n", "--dry-run"].include? arg
    options[:dry_run] = true
  elsif ["-h", "--help"].include? arg
    display_help
  # The following options are for backward compatibility
  elsif File.exists? arg then
    source_file = arg
  elsif VALID_MODELS.include? arg
    model = arg
  elsif Integer(arg, exception: false)
    options[:from] = arg.to_i
  else
    $stderr.puts "Unrecognised option: #{arg}"
    display_help
  end
end

if source_file && model then
  if ! versioning
    VALID_MODELS.each do |model|
      PaperTrail.request.disable_model(model.constantize)
    end
  end
  import = MarcImport.new(source_file, model, options)
  import.import
  $stderr.puts "\nCompleted: " + Time.new.strftime("%Y-%m-%d %H:%M:%S")
else
  display_help
end
