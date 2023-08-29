@headers = [
    :"773w", 
    :"100a", 
    :"1000", 
    :"100j", 
    :"700a", 
    :"7000", 
    :"700j", 
    :"7004", 
    :"245a", 
    :"240a", 
    :"240o",
    :"240k",
    :"240r",
    :"240m", 
    :"650a", 
    :"690a",
    :"690n",
    :"594X", 
    :"041a", 
    :"593a", 
    :"593b",
    :"260c",
    :"300a",
    :"590a",
    :"590b",
    :"300c",
    :"031a",
    :"031b",
    :"031c",
    :"031d",
    :"031m",
    :"031t",
    :"031q",
    :"500a",
    :"599c"
]

@name_cache = {}

def create_or_existing(marc, tag)

    if marc.first_occurance(tag)
        return marc.first_occurance(tag)
    end

    marc_tag = MarcNode.new("source", tag, "", @mc.get_default_indicator(tag))
    marc.root.add_at(marc_tag, marc.get_insert_position(tag) )
    return marc_tag
end

def bruteforce_name(long_name)
    return @name_cache[long_name] if @name_cache.keys.include?(long_name)

    Person.where("full_name LIKE '" + long_name[0,3] + "%'").each do |n|
        if long_name.start_with? n.full_name
            @name_cache[long_name] = n.full_name
            return n.full_name
        end
    end
end

def split_name(long_name)
    long_name.split("(")[0].strip
end

def sheet2muscat(sheet)
    sheet.drop(1).each do |r|
        columns = Hash[@headers.zip r]
    
        source = Source.new
        source.record_type = MarcSource::RECORD_TYPES[:edition_content]
        new_marc = MarcSource.new("", MarcSource::RECORD_TYPES[:edition_content])
    
        marc_tag = MarcNode.new("source", "001", "", @mc.get_default_indicator("001"))
        marc_tag.add_at(MarcNode.new("source", "", "__TEMP__", nil), 0)
        new_marc.root.add_at(marc_tag, new_marc.get_insert_position("001") )
    
        new_marc.reset_to_new
    
        columns.each do |k, v|
    
            next if k == :date
            next if !v
    
            k =~ /([0-9]{3,3})(.)/
            tag = $1
            subtag = $2
    
            #ap tag
            #ap subtag

            if k == :"100a"
                #puts "Was #{v} is #{split_name(v)}"
                v = split_name(v)
            end
            
            # Split the 594 in b c
            if k == :"594X"
                tags = v.split(";")
                tags.each do |t|
                    b, c = t.split(":")

                    marc_tag = MarcNode.new("source", "594", "", @mc.get_default_indicator("594"))
                    marc_tag.add_at(MarcNode.new("source", "b", b.strip, nil), 0 )
                    marc_tag.add_at(MarcNode.new("source", "c", c.strip, nil), 0 )
                    marc_tag.sort_alphabetically
                    new_marc.root.add_at(marc_tag, new_marc.get_insert_position("594") )
                end

                next #exit from the columns.each loop, we are done
            end

            marc_tag = create_or_existing(new_marc, tag)
            marc_tag.add_at(MarcNode.new("source", subtag, v.to_s.gsub("\n", " ").strip, nil), 0 )
            marc_tag.sort_alphabetically
    
        end
    
        new_marc.suppress_scaffold_links
        new_marc.import
    
    
    
        # And save the fresh collection
        source.marc = new_marc
        source.save
    
        puts "Created: #{source.source_id}/#{source.id} #{source.composer} #{source.std_title}"
    
        #ap source.marc
        #puts
    end
end

data = Roo::Spreadsheet.open('gardano.ods')
@mc = MarcConfigCache.get_configuration("source")

data.each_with_pagename do |name, sheet|

    begin
        s = Source.find(name)
    rescue ActiveRecord::RecordNotFound
        puts "Source #{name} was deleted".red
        next
    end

    puts "processing #{name}"
    sheet2muscat(sheet)
end