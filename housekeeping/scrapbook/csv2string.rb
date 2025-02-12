require 'csv'
require 'yaml'
require 'zlib'
require 'base64'

def csv_to_base64_gzipped_yaml(csv_file_path)
  # 1. Read the CSV file and build a hash
  data_array = []
  CSV.foreach(csv_file_path, headers: false) do |row|
    key, value = row
    data_array << [key, value]
  end

  # 2. Convert the hash to a YAML string
  yaml_str = data_array.to_yaml

  # 3. Gzip the YAML string
  compressed = Zlib::Deflate.deflate(yaml_str)
  # 4. Base64-encode the compressed data
  Base64.strict_encode64(compressed)
end



base64_string = csv_to_base64_gzipped_yaml(ARGV[0])
File.open("output.txt", "w") do |file|
    file.write base64_string
end