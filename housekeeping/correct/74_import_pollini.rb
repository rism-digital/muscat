require "rexml/document" 
include REXML

def add_tag(marc, tag, subtags = {})
    mc = MarcConfigCache.get_configuration("work")

    the_t = MarcNode.new("work", tag, "", mc.get_default_indicator(tag))

    subtags.each do |stag, val|
        the_t.add_at(MarcNode.new("work", stag.to_s, val, nil), 0 )
    end

    the_t.sort_alphabetically
    marc.root.add_at(the_t, marc.get_insert_position(tag))
    return the_t
end

def append_to_tag(marc, tag, subtags = {}, the_t = nil)

    if the_t
        t = the_t
    else
        t = marc.first_occurance(tag)
    end

    if !t #oops!
        add_tag(marc, tag, subtags)
        return
    end

    subtags.each do |stag, val|
        t.add_at(MarcNode.new("work", stag.to_s, val, nil), 0 )
    end

    t.sort_alphabetically
end

@yet_another_name_map = {
    "Giulia Bertoglio Roero di Settime" => "Bertoglio Roero di Settime, Giulia",
"Giulia Roero di Settime nata Bertoglio" => "Bertoglio Roero di Settime, Giulia",
"Julius Klengel after James Macpherson" => "Klengel, Julius",
"King Christian VIII of Denmark" => "Christian VIII., konge til Danmark"
}

def magic_name(name)
    return name if name.include?(",")

    if @yet_another_name_map.keys.include?(name.strip)
        return @yet_another_name_map[name.strip]
    end

    parts = name.strip.split(" ")

    if parts.count == 1
        return name
    elsif parts.count == 2
        return "#{parts[1]}, #{parts[0]}"
    elsif parts.count == 3
        return "#{parts[2]}, #{parts[0]} #{parts[1]}"
    end

    return name
end

def process_one_file(file_name)

    created_at = Date.today
    referring_source = nil

    new_marc = MarcWork.new("=001 __TEMP__\n")
    doc = REXML::Document.new(File.open(file_name))

    XPath.each(doc, "/mei/meiHead/workList/work/contributor/persName") do |name|
        if name["role"] != "composer"
            tgs = {a: magic_name(name.text)}

            if name["role"] == "dedicatee"
                tgs[:"4"] = "dte"
            elsif name["role"] == "lyricist"
                tgs[:"4"] = "lyr"
            else
                tgs[:"4"] = "oth"
            end
            
            add_tag(new_marc, "700", tgs)

        else
            add_tag(new_marc, "100", {a: magic_name(name.text)})
        end
    end

    XPath.each(doc, "/mei/meiHead/workList/work/title") do |data|
        if data["type"] == "subordinate" || data["type"] == "alternative" || data["type"] == "original"
            add_tag(new_marc, "430", {a: data.text})
        else

            add_tag(new_marc, "130", {a: data.text}) if data["lang"] == "en"
        end
    end

    # did we add a 130?
    if !new_marc.first_occurance("130")
        # no, do it again and try to get the italian title
        XPath.each(doc, "/mei/meiHead/workList/work/title") do |data|
            if data["type"] == "subordinate" || data["type"] == "alternative" || data["type"] == "original"
            else
                add_tag(new_marc, "130", {a: data.text}) if data["lang"] == "it"
            end
        end
    end

    XPath.each(doc, "/mei/meiHead/workList/work/identifier") do |data|
        add_tag(new_marc, "383", {b: data.text}) if data["label"] == "Opus"
    end

    ## THIS SEEMS TO BE EMPTY
    XPath.each(doc, "/mei/meiHead/workList/work/contributor/corpName") do |data|
        #add_tag(new_marc, "710", {a: data.text})
    end

    ## THIS TOO SEEMS TO BE EMPTY
    XPath.each(doc, "/mei/meiHead/workList/work/title[@type='text_source']") do |data|
        #add_tag(new_marc, "680", {a: data.text})
    end

    XPath.each(doc, "/mei/meiHead/workList/work/notesStmt/annot/p") do |data|
        alltext = ""
        data.texts.each do |t|
            alltext += t.to_s.strip
        end
        add_tag(new_marc, "680", {a: alltext}) if !alltext.empty?    
    end

    ## These are relationships, FIXME how to translate?
    XPath.each(doc, "/mei/meiHead/workList/work/relationList/relation") do |data|
        ###add_tag(new_marc, "530", {a: data["label"]}) if data["label"]
        ## FIXME
    end

    XPath.each(doc, "/mei/meiHead/workList/work/creation/geogName") do |data|
        #add_tag(new_marc, "370", {g: data.text})
    end

    XPath.each(doc, "/mei/meiHead/workList/work/creation/date") do |data|
        #add_tag(new_marc, "046", {k: data.text})
    end

    XPath.each(doc, "/mei/meiHead/workList/work/history/p") do |data|
        alltext = ""
        data.texts.each do |t|
            alltext += t.to_s.strip
        end
        add_tag(new_marc, "680", {a: alltext}) if !alltext.empty?
    end

    # FIXME does it catch all?
    XPath.each(doc, "/mei/meiHead/workList/work/history/eventList[@type='performances']/event/corpName") do |data|
        add_tag(new_marc, "710", {a: data.text}) if data.text && !data.text.empty?
    end

    # FIXME does it catch all?
    # "Nicolaus Lützhøft,\n                                singer"
    # "Holger Dahl,\n                                piano"
    XPath.each(doc, "/mei/meiHead/workList/work/history/eventList[@type='performances']/event/persName") do |data|
        add_tag(new_marc, "710", {a: data.text, "4": "oth"}) if data.text && !data.text.empty?
    end

    ################################################################################################
    # BEGIN INCIPIT STUFF
    ################################################################################################

    incipits = []

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/incip/incipCode") do |data|
        incipits << add_tag(new_marc, "031", {p: data.text}) if data.text && !data.text.empty?
    end

    def fill_incipit(paths, doc, new_marc, incipits)
        paths.each do |path, subtag|
            count = 0
            XPath.each(doc, path.to_s) do |data|
                append_to_tag(new_marc, "031", {subtag => data.text.strip}, incipits[count]) if data.text && !data.text.strip.empty?
                count +=1 if count < incipits.count - 1
            end
        end
    end

    map = {
    "/mei/meiHead/workList/work/expressionList/expression/perfMedium/perfResList" => "m",
    "/mei/meiHead/workList/work/expressionList/expression/perfMedium/castList/castItem/role/name" => "e",
    "/mei/meiHead/workList/work/expressionList/expression/incip/tempo" => "d",
    "/mei/meiHead/workList/work/expressionList/expression/incip/meter" => "o",
    "/mei/meiHead/workList/work/expressionList/expression/incip/key" => "n",
    #"/mei/meiHead/workList/work/expressionList/expression/extent" => "m",
    "/mei/meiHead/workList/work/expressionList/expression/incip/incipText" => "t",
    "/mei/meiHead/workList/work/expressionList/expression/componentList" => "q"
    }

    fill_incipit(map, doc, new_marc, incipits)

=begin
    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/perfMedium/perfResList") do |data|
        append_to_tag(new_marc, "031", {m: data.text}) if data.text && !data.text.empty?
    end

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/perfMedium/castList/castItem/role/name") do |data|
        append_to_tag(new_marc, "130", {e: data.text}) if data.text && !data.text.empty?
    end

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/incip/tempo") do |data|
        append_to_tag(new_marc, "130", {d: data.text}) if data.text && !data.text.empty?
    end

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/incip/meter") do |data|
        #ap data
    end

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/incip/key") do |data|
        #ap data
    end

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/extent") do |data|
        #ap data
    end

    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/incip/incipText") do |data|
        #ap data
    end


    XPath.each(doc, "/mei/meiHead/workList/work/expressionList/expression/componentList") do |data|
        #ap data
    end
=end

    ################################################################################################
    # END INCIPIT STUFF
    ################################################################################################

    ## FIXME database field?
    XPath.each(doc, "/mei/meiHead/manifestationList/manifestation/identifier") do |data|

        referring_source = data.text
    end

    ## FIXME This seems empty?
    XPath.each(doc, "/mei/meiHead/workList/work/biblList/bibl") do |data|
        all_lines = []
        all_lines << data.elements["author"].text.strip if data.elements["author"] && data.elements["author"].text
        all_lines << data.elements["editor"].text.strip if data.elements["editor"] && data.elements["editor"].text
        all_lines << data.elements["title"].map {|t| t.to_s.strip} if data.elements["title"]

        add_tag(new_marc, "667", {a: "biblList entry: " + all_lines.join(", ")})     
    end

    # FIXME set created-at?
    XPath.each(doc, "/mei/meiHead/revisionDesc/change") do |data|
        created_at = Date.parse(data["isodate"])
    end

    ## FIXME This seems empty?
    XPath.each(doc, "/mei/meiHead/fileDesc/notesStmt") do |data|
        # data.texts
    end

    ## FIXME I don't think we have a DB entry for this
    XPath.each(doc, "/mei/meiHead/workList/work/langUsage") do |data|
        #ap data
    end

    XPath.each(doc, "/mei/meiHead/workList/work/classification/termList/term") do |data|
        add_tag(new_marc, "380", {a: data.text}) if data.text && !data.text.empty?
        append_to_tag(new_marc, "130", {m: data.text}) if data.text && !data.text.empty?
    end

    XPath.each(doc, "/mei/meiHead/fileDesc/pubStmt/respStmt/corpName/expan") do |data|
        add_tag(new_marc, "040", {a: data.text.strip}) if data.text && !data.text.empty?
    end

    # Nothing to do here
    XPath.each(doc, "/mei/meiHead/pubStmt/respStmt/persName") do |data|
        #ap data
    end

    # Nothing to do here
    XPath.each(doc, "/mei/meiHead/pubStmt/availability/useRestrict") do |data|
        #ap data
    end

    XPath.each(doc, "/mei/meiHead/fileDesc/seriesStmt/title") do |data|
        add_tag(new_marc, "690", {a: data.text.strip}) if data.text && !data.text.empty?
    end

    # Nothing to do here
    XPath.each(doc, "/mei/meiHead/encodingDesc/appInfo/application/name") do |data|
        #ap data
    end

    return new_marc, created_at, referring_source
end

DIR = ARGV[0]

Dir.glob("#{DIR}/*.xml").each do |file|
    #puts "Process #{file}".green
    marc, created_at, referring_source = process_one_file(file)
    #ap marc

    rs = Source.find(referring_source) if referring_source rescue rs = nil

    marc.import

    work = Work.new
    work.marc = marc

    work.referring_sources << rs if rs

    work.created_at = created_at
    work.composer = work.marc.get_composer
    work.save
end

Sunspot.commit