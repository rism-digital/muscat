# encoding: UTF-8
puts "##########################################################################################"
puts "################################## Export to MarcXML #####################################"
puts "##########################################################################################"
puts ""

require 'optparse'

# Default options
@options = {
    :model_name => 'Source',
    :filename => "./export.xml",
    :legacy => false
}

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-m', '--model NAME', 'Model name') { |v| @options[:model_name] = v }
  opts.on('-f', '--file FILE', 'Filename') { |v| @options[:filename] = v }
  opts.on("-l", "--legacy", "Enable legacy mode") { @options[:legacy] = true }
end.parse!

# Retrieve the class
model = @options[:model_name].classify.constantize
# For sources limit to published records
published_only = (@options[:model_name] == "Source") ? {:wf_stage => 1} : {}

# list of ids
items = model.where(published_only).order(:id).pluck(:id)

file = File.open(@options[:filename], "w")
file.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<collection xmlns=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n")

bar = ProgressBar.new(items.size)

items.each do |s|
  record = model.find(s)
  # Add deprecated_ids: "false" if necessary
  file.write(record.marc.to_xml_record({ created_at: record.created_at, updated_at: record.updated_at, holdings: true }).root.to_s)

  bar.increment!
  record = nil
end

file.write("\n</collection>")
file.close
