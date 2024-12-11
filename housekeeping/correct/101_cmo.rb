@mc = MarcConfigCache.get_configuration("person")

def preprocess_cmo(marc, obj, options)
    #puts "Callback to process #{obj.id}"

    cmo_id = marc.first_occurance("001").content
    
    # Remove the old 001
    marc.by_tags("001").each {|t2| t2.destroy_yourself}

    # And make a new one
    # Add it in position 1 since there is a 000 in the original data
    marc.root.add_at(MarcNode.new("person", "001", "__TEMP__", nil), 1)

    n024 = MarcNode.new("person", "024", "", @mc.get_default_indicator("024"))
   
    n024.add_at(MarcNode.new("person", "a", cmo_id, nil), 0 )
    n024.add_at(MarcNode.new("person", "2", "cmo", nil), 0 )
    n024.sort_alphabetically
    marc.root.add_at(n024, marc.get_insert_position("024") )

    # We moved this to 024
    marc.by_tags("100").each do |t|
        t.fetch_all_by_tag("0").each {|tt| tt.destroy_yourself}
    end

    marc.by_tags("670").each do |t|
        #is there a $b?
        b = t.fetch_first_by_tag("b")
        if b && b.content
            ## Move it to an  note
            n680 = MarcNode.new("person", "680", "", @mc.get_default_indicator("680"))
            n680.add_at(MarcNode.new("person", "a", b.content, nil), 0 )
            n680.sort_alphabetically
            marc.root.add_at(n680, marc.get_insert_position("680") )
        end

        a = t.fetch_first_by_tag("a")

        if !a || !a.content || a.content.empty?

            #puts "Remove empty #{t}"
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

    marc.by_tags("024").each do |t|
        a = t.fetch_first_by_tag("a")

        if !a || !a.content || a.content.empty?
            puts "Remove empty #{t}"
            t.destroy_yourself
        end
    end

    marc.by_tags("400").each do |t|
        a = t.fetch_first_by_tag("a")
        w = t.fetch_first_by_tag("w")

        if w && w.content
            # Move to internal note
            n667 = MarcNode.new("person", "677", "", @mc.get_default_indicator("667"))
            n667.add_at(MarcNode.new("person", "a", "#{a&.content} | #{w.content}", nil), 0 )
            n667.sort_alphabetically
            marc.root.add_at(n667, marc.get_insert_position("667") )
        end

        # Remove it
        t.fetch_all_by_tag("w").each {|tt| tt.destroy_yourself}
    end

    return marc
end

files = Dir.glob("CMO-MARCXML/Person/*.xml")

#source_file = "CMO-MARCXML/Person/cmo_person_00000001.xml"

# Minimal option set
options = {first: 0, last: 1000000, versioning: false, index: false}

options[:new_ids] = true
options[:authorities] = true
options[:callback] = method(:preprocess_cmo)

$MARC_DEBUG=true
$MARC_LOG=[]
$MARC_FORCE_CREATION = false

complete_log = []

files.each do |source_file|
    puts source_file
    import = MarcImport.new(source_file, "Person", options)
    import.import

    $MARC_LOG.each do |l|
        next if l[0] == "MARC"
        complete_log << l.join("\t")
    end
    $MARC_LOG = []
end

complete_log.sort.uniq.each {|l| puts l}