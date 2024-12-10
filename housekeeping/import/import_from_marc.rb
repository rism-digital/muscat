# Import Marcxml records into Muscat database
# Run as bin/rails runner housekeeping/import/import_from_marc.rb

VALID_MODELS = ["Source", "Publication", "Person", "Institution", "Holding", "Work"]

def display_help
  script = "bin/rails runner #{$0}"
  puts "Import marcxml records into Muscat database

Usage:  #{script} [options]

Options:
 -i, --input, --file input file name, required
 -t, --type          record type; choose one of: #{VALID_MODELS.join(', ')}
 -f, --first         first record to import
 -l, --last          last record to import
 -v, --versioning    update records version
 -u, --authorities   create (scaffold) related Marc authorities records
 -x, --index         index records as they are imported
 -n, --new-ids       don't preserve imported ids, but assign new ones (default is to preserve)
 -h, --help          this help

This script can also be run with positional arguments:

 #{script} filename type [first]
"
  exit false
end


runs_under_rails = Rails.initialized? rescue nil
if !runs_under_rails
  $stderr.puts "This script has to be run under Rails"
  display_help
end

source_file = nil
model = nil
options = {
  first: 0,
  last: 9999999,
  versioning: false,
  authorities: false,
  index: false,
}

while ARGV.any? do
  arg = ARGV.shift
  if ["-i", "--input", "--file"].include? arg
    if ARGV.any?
      arg = ARGV.shift
      if File.exist? arg
        source_file = arg
      else
        $stderr.puts "#{arg} is not a file!"
        exit false
      end
    end
  elsif ["-t", "--type"].include? arg
    if ARGV.any?
      arg = ARGV.shift
      if VALID_MODELS.include? arg
        model = arg
      else
        $stderr.puts "Invalid record type: #{arg}\nValid values are: #{VALID_MODELS.join(', ')}"
        exit false
      end
    end
  elsif ["-f", "--first"].include? arg
    if ARGV.any?
      arg = ARGV.shift
      if Integer(arg, exception: false)
        options[:first] = arg.to_i
      else
        $stderr.puts "Non-numeric argument: #{arg}"
        exit false
      end
    else
      $stderr.puts "Missing numeric argument: #{arg}"
      exit false
    end
  elsif ["-l", "--last"].include? arg
    if ARGV.any?
      arg = ARGV.shift
      if Integer(arg, exception: false)
        options[:last] = arg.to_i
      else
        $stderr.puts "Non-numeric argument: #{arg}"
        exit false
      end
    else
      $stderr.puts "Missing numeric argument: #{arg}"
      exit false
    end
  elsif ["-v", "--versioning"].include? arg
    options[:versioning] = true
  elsif ["-u", "--authorities"].include? arg
    options[:authorities] = true
  elsif ["-x", "--index"].include? arg
    options[:index] = true
  elsif ["-n", "--new-ids"].include? arg
    options[:new_ids] = true
  elsif ["-h", "--help"].include? arg
    display_help
  # The following options are for backward compatibility
  elsif File.exist? arg
    source_file = arg
  elsif VALID_MODELS.include? arg
    model = arg
  elsif Integer(arg, exception: false)
    options[:from] = arg.to_i
  else
    $stderr.puts "Unrecognized option: #{arg}"
    display_help
  end
end

if source_file && model
  if !options[:versioning]
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
