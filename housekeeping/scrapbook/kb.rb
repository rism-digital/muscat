require "crack"
require "json"

myXML  = Crack::XML.parse(File.read("KbIndex.xml"))
myJSON = myXML.to_json

#puts JSON.pretty_generate(myXML)