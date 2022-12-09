
=begin
"Alternative. Title":
"Authorities"
"Average DurationAvg. Duration"
"Composer"
"Composer Time PeriodComp. Period"
"Copyright Information"
"Dedication"
"Discography"
"External Links"
"Extra Information"
"Extra Locations"
"First Performance."
First Publication.
I-Catalogue NumberI-Cat. No.
Instrumentation
Key
Language
Librettist
Movements/SectionsMov'ts/Sec's
Name Aliases
Name Translations
Opus/Catalogue NumberOp./Cat. No.
Piece Style
Primary Sources
Related Works
Templates
Text Incipit
Work Title
Year/Date of CompositionY/D of Comp.
=end

def export_list(cell)

    title = cell.children.find.first.text
    title = title.strip if title
    elements = cell.search("li").collect {|li| li.text.strip}
    
    {"title": title, "elements": elements}

end

def rip_page(url)
    uri = URI(URI::Parser.new.escape(url))
    response = Net::HTTP.get(uri)

    doc = Nokogiri::HTML.parse(response)

    workinfo = doc.at('.wi_body')
    return ["url": url] if !workinfo

    info = {}

    workinfo.search('tr').each do |tr|
        cells = tr.search('th, td')
        key = cells[0].text.strip rescue key = "n.a."
        content = cells[1].text.strip rescue content = "n.a." 

        next if key == "Copyright Information"

        if key == "Name Translations" || key == "Name Aliases" || key == "Authorities" || key == "Instrumentation"
            if content.include?("; ")
                content = content.split("; ")
            else
                content = content.split("\n")
            end
        end

        if key == "Movements/SectionsMov'ts/Sec's" || key == "Text Incipit" || key == "Librettist"
            content = export_list(cells[1])
        end

        info[key] = content
    end

    info["url"] = url
    info
end

out = []
count = 0
urls = YAML.load(File.read("permlinks.yml"))

#urls = ["https://imslp.org/wiki/6_Violin_Sonatas_and_Partitas,_BWV_1001-1006_(Bach,_Johann_Sebastian)"]
#urls = ["https://imslp.org/wiki/12_Duette,_Op.576_(Abt,_Franz)"]

urls.first(100).each do |url|
    #ap URI::Parser.new.escape(url)
    data = rip_page(url) rescue data = ["url": url]
    out << data
    count += 1
    puts count if count % 10 == 0
end

File.open("big0.yml", "w") { |file| file.write(out.to_yaml) }


#https://imslp.org/wiki/%22Los_ojos_tiernos%22_(Esnaola,_Juan_Pedro)