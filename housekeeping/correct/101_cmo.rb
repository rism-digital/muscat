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
    n024.add_at(MarcNode.new("person", "2", "CMO", nil), 0 )
    n024.sort_alphabetically
    marc.root.add_at(n024, marc.get_insert_position("024") )

    n040 = MarcNode.new("person", "040", "", @mc.get_default_indicator("040"))
    n040.add_at(MarcNode.new("person", "a", "DE-4353", nil), 0 )
    n040.add_at(MarcNode.new("person", "b", "eng", nil), 0 )
    n040.add_at(MarcNode.new("person", "c", "DE-633", nil), 0 )
    n040.sort_alphabetically
    marc.root.add_at(n040, marc.get_insert_position("040") )

    # We moved this to 024
    marc.by_tags("100").each do |t|
        t.fetch_all_by_tag("0").each {|tt| tt.destroy_yourself}
    end

    marc.by_tags("678").each do |t|
        # is there a $b and no $a? Then it is a name!
        a = t.fetch_first_by_tag("a")
        b = t.fetch_first_by_tag("b")
        if (b && b.content) && !a
            ## Move it to an  note
            n680 = MarcNode.new("person", "680", "", @mc.get_default_indicator("680"))
            n680.add_at(MarcNode.new("person", "a", b.content, nil), 0 )
            n680.sort_alphabetically
            marc.root.add_at(n680, marc.get_insert_position("680") )
            puts "Moved date to 680"
        end

        # We have stuff in $w too
        w = t.fetch_first_by_tag("w")
        b = t.fetch_first_by_tag("b")

        # This field can also contain bib info!
        # see cmo_person_00000497
        if a && a.content && !a.content.empty?
            # There is bib data to move
            # Do some magics
            parts = a.content.split(", ")

            # Remove the unwanted spaces...
            sanitized = parts[0].split.join(" ")

            n670 = MarcNode.new("person", "670", "", @mc.get_default_indicator("670"))

            n670.add_at(MarcNode.new("person", "a", sanitized, nil), 0 ) # Add the revue name
            n670.add_at(MarcNode.new("person", "9", parts[1], nil), 0 )if parts[1]  # add the pages

            # Move the other things
            n670.add_at(MarcNode.new("person", "b", b&.content, nil), 0 ) if b && b.content
            n670.add_at(MarcNode.new("person", "u", w&.content, nil), 0 ) if w && w.content

            n670.sort_alphabetically
            marc.root.add_at(n670, marc.get_insert_position("670") )
        end

    end

    # Purge all the 678
    marc.by_tags("678").each {|t| t.destroy_yourself}

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
            n667 = MarcNode.new("person", "667", "", @mc.get_default_indicator("667"))
            n667.add_at(MarcNode.new("person", "a", "#{a&.content} | #{w.content}", nil), 0 )
            n667.sort_alphabetically
            marc.root.add_at(n667, marc.get_insert_position("667") )
        end

        # Remove it
        t.fetch_all_by_tag("w").each {|tt| tt.destroy_yourself}
    end

    # move 1 to u
    marc.by_tags("910").each do |t|
        t.fetch_all_by_tag("1").each {|tt| tt.tag = "u"}
    end

    return marc
end

DIR="cmo_person_marcxml_20241213"
#CMO-MARCXML/Person/

files = Dir.glob("#{DIR}/*.xml")

#source_file = "CMO-MARCXML/Person/cmo_person_00000001.xml"

# Minimal option set
options = {first: 0, last: 1000000, versioning: false, index: true}

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
Sunspot.commit
complete_log.sort.uniq.each {|l| puts l}