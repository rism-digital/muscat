@headers = [:"773w", :"100a", :"100q", :"245a", :"240a", :"240m", :"650a", :"594a", :"041a", :"593a", :date, :"300a", :"590a", :"590b", :"031m", :"031d"]

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
    sheet.drop(2).each do |r|
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
    
            if k == :"100a"
                puts "Was #{v} is #{split_name(v)}"
                v = split_name(v)
            end
    
            marc_tag = create_or_existing(new_marc, tag)
            marc_tag.add_at(MarcNode.new("source", subtag, v.to_s.gsub("\n", " "), nil), 0 )
            marc_tag.sort_alphabetically
    
        end
    
        new_marc.suppress_scaffold_links
        new_marc.import
    
    
    
        # And save the fresh collection
        source.marc = new_marc
        source.save
    
        puts source.id
    
        #ap source.marc
        #puts
    end
end

data = Roo::Spreadsheet.open('import_children.ods')
@mc = MarcConfigCache.get_configuration("source")

data.each_with_pagename do |name, sheet|
    puts "processing #{name}"
    sheet2muscat(sheet)
end