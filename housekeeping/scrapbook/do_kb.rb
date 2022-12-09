require "rexml/document" 
include REXML

output = []

doc = REXML::Document.new(File.open("KbIndex..xml"))

XPath.each(doc, "/index/group[@name='Composers']/group") do |name|
    composer = name.attributes['name']
    XPath.each(name, "/index/group[@name='Composers']/group[@name='#{composer}']/group[@name='Feasts']/group") do |feast|
        feast_name = feast.attributes['name']
        XPath.each(name, "/index/group[@name='Composers']/group[@name='#{composer}']/group[@name='Feasts']/group[@name='#{feast_name}']/link") do |link|
            label =  link.attributes['label']
            target = link.attributes['target']

            date, page = label.split(" - ")

            output << {
                composer: composer,
                feast: feast_name,
                date: date,
                page: page,
                target: target
            }

        end
    end
end

puts output.to_json