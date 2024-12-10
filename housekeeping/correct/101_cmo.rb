def preprocess_cmo(marc, obj, options)
    #puts "Callback to process #{obj.id}"

    # Remove the old 001
    marc.by_tags("001").each {|t2| t2.destroy_yourself}

    # And make a new one
    # Add it in position 1 since there is a 000 in the original data
    marc.root.add_at(MarcNode.new("person", "001", "__TEMP__", nil), 1)

    marc.by_tags("670").each do |t|
        a = t.fetch_first_by_tag("a")
        
        if !a || !a.content || a.content.empty?
            puts "Remove empty #{t}"
            t.destroy_yourself
        else
            # Do some magics
            parts = a.content.split(", ")
            a.content = parts[0]

            if parts[1]
                t.add_at(MarcNode.new("person", "9", parts[1], nil), 0 )
                t.sort_alphabetically
            end

        end
    end

    return marc
end

files = Dir.glob("CMO-MARCXML/Person/*.xml")

#source_file = "CMO-MARCXML/Person/cmo_person_00000001.xml"

# Minimal option set
options = {first: 0, last: 1000000, versioning: false, index:false}

options[:new_ids] = true
options[:authorities] = true
options[:callback] = method(:preprocess_cmo)

files.each do |source_file|
    puts source_file
    import = MarcImport.new(source_file, "Person", options)
    import.import
end