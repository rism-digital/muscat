# encoding: UTF-8
puts "##########################################################################################"
puts "################################## Export to MarcXML #####################################"
puts "##########################################################################################"
puts ""

# export model with default
model_name = ARGV[0] ? ARGV[0] : "Source"
model = model_name.classify.constantize
# export file with default
filename = ARGV[1] ? ARGV[1] : "./export.xml"
# For sources limit to published records
published_only = (model_name == "Source") ? {:wf_stage => 1} : {}

# list of ids
items = model.where(published_only).order(:id).pluck(:id)

file = File.open(filename, "w")
file.write("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<collection xmlns=\"http://www.loc.gov/MARC21/slim\" xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:schemaLocation=\"http://www.loc.gov/MARC21/slim http://www.loc.gov/standards/marcxml/schema/MARC21slim.xsd\">\n")

bar = ProgressBar.new(items.size)

items.each do |s|
  record = model.find(s)

  file.write(record.marc.to_xml_record({ created_at: record.created_at, updated_at: record.updated_at, holdings: true }).root.to_s)

  bar.increment!
  record = nil
end

file.write("\n</collection>")
file.close
