require 'csv'
require 'yaml'
require 'zlib'
require 'base64'

def csv_to_base64_gzipped_yaml(csv_file_path, hash = true)
  data_array = hash ? Hash.new : Array.new
  puts "Converting #{csv_file_path} to a #{data_array.class}"

  CSV.foreach(csv_file_path, headers: false) do |row|
    key, value, val2 = row
    data_array << [key, value, val2] if !hash
    data_array[key] = value if hash
  end

  # 2. Convert the hash to a YAML string
  yaml_str = data_array.to_yaml

  # 3. Gzip the YAML string
  compressed = Zlib::Deflate.deflate(yaml_str)
  # 4. Base64-encode the compressed data
  Base64.strict_encode64(compressed)
end

hash = true
if ARGV.count > 1
  hash = false if ARGV[1].downcase == "array"
end

base64_string = csv_to_base64_gzipped_yaml(ARGV[0], hash)
File.open("output.txt", "w") do |file|
    file.write base64_string
end