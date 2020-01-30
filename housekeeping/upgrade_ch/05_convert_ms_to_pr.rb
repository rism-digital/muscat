## There is no C column!!!!!
headers = [:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y, :z, :aa, :ab, :ac, :ad, :ae, :af]

items = []

# Disable snapshots?
#PaperTrail.request.disable_model(Source)

def fetch_single_subtag(marctag, subtag)
    st = marctag.fetch_first_by_tag(subtag)
    if st && st.content
      return st.content
    end
    return nil
end

def delete_single_subtag(marctag, subtag)
    st = marctag.fetch_first_by_tag(subtag)
    st.destroy_yourself if st
end

def replace_single_subtag(marctag, subtag, value)
    delete_single_subtag(marctag, subtag)
    marctag.add_at(MarcNode.new("source", subtag, value, nil), 0)
    marctag.sort_alphabetically
end

def insert_single_marc_tag(marc, tag, subtag, value)
    new_tag = MarcNode.new("source", tag, "", "##")
    new_tag.add_at(MarcNode.new("source", subtag, value, nil), 0)
    new_tag.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position(tag), new_tag)
end

def tag_contains_value(marctag, subtag, value)
    marctag.each_by_tag(subtag) do |st|
        next if !st || !st.content
        return true if st.content == value
    end
    false
end

def count_marc_tag(marc, tag)
    return marc.by_tags(tag).count
end

def remove_marc_tag(marc, tag)
    marc.by_tags(tag).each {|t| t.destroy_yourself}
end

def rename_marc_tag(marc, tag, new_tag)
    marc.each_by_tag(tag) do |t|
        t.tag = new_tag
    end
end

def copy_tag(marc, new_marc, tag, new_tag_name = nil)
    marc.by_tags(tag).each do |old_tag|            
        new_tag = old_tag.deep_copy
        if new_tag_name
            new_tag.tag = new_tag_name
        end
        new_marc.root.children.insert(new_marc.get_insert_position(new_tag.tag), new_tag)
    end
end

def move_tag_with_subtag(marc, new_marc, tag, subtag, subtag_val)
    marc.by_tags(tag).each do |old_tag|   
        next if !tag_contains_value(old_tag, subtag, subtag_val)

        new_tag = old_tag.deep_copy
        new_marc.root.children.insert(new_marc.get_insert_position(new_tag.tag), new_tag)
        old_tag.destroy_yourself
    end
end

def tag_to_text(marc, tag, groups)

    text = marc.by_tags(tag).map do |t|
        grp = t.fetch_first_by_tag("8")
        next if !grp || !grp.content
        next if !groups.include?(grp.content.to_i)
    
        t.map do |st|
            next if st.tag == "8"
            next if st.tag == tag
            "#{st.tag} #{st.content}"
        end.compact.join(", ") + " [#{grp.content}]"

    end.compact

    if !text.empty?
        "#{tag}: " + text.join("; ")
    else
        nil
    end

end

def groups_to_human_readable_text(marc, group)
    tokens = []

    tags = marc.by_tags_with_subtag(["593"], "8", group)
    tags.each do |t|
        tokens << fetch_single_subtag(t, "a")
    end

    tags = marc.by_tags_with_subtag(["260"], "8", group)
    tags.each do |t|
        info = []
        t.each_by_tag("a") do |st|
            next if !st || !st.content
            info << st.content
        end
        info << fetch_single_subtag(t, "b")
        info << fetch_single_subtag(t, "c")
        info << fetch_single_subtag(t, "e")
        info << fetch_single_subtag(t, "r")
        tokens << info.compact.join(", ")
    end

    tags = marc.by_tags_with_subtag(["300"], "8", group)
    tags.each do |t|
        info = []
        t.each_by_tag("a") do |st|
            next if !st || !st.content
            info << st.content
        end

        t.each_by_tag("b") do |st|
            next if !st || !st.content
            info << st.content
        end

        info << fetch_single_subtag(t, "c")
        tokens << info.compact.join(", ")
    end

    tags = marc.by_tags_with_subtag(["590"], "8", group)
    tags.each do |t|
        info = []
        info << fetch_single_subtag(t, "a")
        info << fetch_single_subtag(t, "b")
        tokens << info.compact.join(", ")
    end

    tokens.compact.join("; ")
end

def migrate_590(new_marc, the590)
    the8 = nil
    # pull the 852
    the852 = new_marc.first_occurance("852")
    the8 = the852.fetch_first_by_tag("8") if the852
    if the8 && the8.content
        # Substitute the existing one
        the8.content = fetch_single_subtag(the590, "a")
    else
        # Append a new one
        the852.add_at(MarcNode.new("source", "q", fetch_single_subtag(the590, "a"), nil), 0)
        the852.sort_alphabetically
    end
    
    # Remove the $8 and make it a regular 590
    ##the590.each_by_tag("8") {|the8| the8.destroy_yourself}
end

def copy_group(marc, new_marc, group)
    marc.all_tags.each do |tgs|
        grp = tgs.fetch_first_by_tag("8")
        next if !grp || !grp.content
        
        if grp.content.to_i == group
            if tgs.tag == "590"
                migrate_590(new_marc, tgs)
            else
                new_marc.root.children.insert(new_marc.get_insert_position(tgs.tag), tgs.deep_copy)
            end
        end
    end
end

def delete_group(marc, group)
    tags_to_delete = []
    marc.all_tags.each do |tgs|
        grp = tgs.fetch_first_by_tag("8")
        next if !grp || !grp.content
        
        if grp.content.to_i == group.to_i
            #tgs.destroy_yourself
            tags_to_delete << tgs
        end
    end
    
    # Make sure we iterate over all the tags to remove!
    tags_to_delete.each {|tag| tag.destroy_yourself}
end

def move_or_not_tag(marc, new_marc, tag, source_row)
    return if !source_row || source_row.empty?

    if source_row == "move"
        copy_tag(marc, new_marc, tag)
        remove_marc_tag(marc, tag)
    elsif source_row == "delete"
        remove_marc_tag(marc, tag)
    else
        puts "I don't understand #{source_row} for #{tag}".purple if !source_row.include?("man")
    end

end


## Note, in some cases (408000789), the new record does not
# have a 773, but the parent gets updated because we
# use old_record as a basis
# FIXME should we add the 773 in new record?
def update_parent_ms(marc, old_record, new_record)
    parent_manuscript_id = marc.first_occurance("773", "w")
    
    # NOTE we evaluate the strings prefixed by 00000
    # as the field may contain legacy values
    
    return if !parent_manuscript_id
    # We have a parent manuscript in the 773
    # Open it and add, if necessary, the 774 link

    parent_manuscript = Source.find_by_id(parent_manuscript_id.content)
    if !parent_manuscript
        puts "UPDATE 774 PARENT NOT FOUND, did it change id? #{parent_manuscript_id.content}".red
    end
    
    # Update the parent for the new record
    new_record.source_id = parent_manuscript.id

    parent_manuscript.marc.load_source false

    # check if the 774 tag already exists
    parent_manuscript.marc.each_data_tag_from_tag("774") do |tag|
        subfield = tag.fetch_first_by_tag("w")
        next if !subfield || !subfield.content
        if subfield.content.to_i == old_record.id
            subfield.content = new_record.id
            
            puts "Saving #{parent_manuscript_id.content}"

            parent_manuscript.paper_trail_event = "CH Migration update 774 #{old_record.id} #{new_record.id}"
            parent_manuscript.marc.import
            parent_manuscript.suppress_reindex
            parent_manuscript.suppress_update_count
            parent_manuscript.suppress_update_77x
            parent_manuscript.save

            puts "Update 774 in #{parent_manuscript_id.content} from #{old_record.id} to #{new_record.id}".green
        end
    end
end
    

def create_holding(row, source, marc, replace = nil, old_siglum = nil, only_group = nil, additional_notes = nil)
    holding = nil
    new_marc = nil

    if replace
        # A holding already exists, just get that one
        holdings = Holding.where(source_id: replace, lib_siglum: old_siglum)
        if holdings.count == 0
            puts "No holding found for #{replace} and #{old_siglum}".red
            replace = false # Just add one
        elsif holdings.count > 1
            puts "Multiple holdings found for #{replace} and #{old_siglum}".red
            return
        else

            holding = holdings.first
            new_marc = holding.marc
            new_marc.load_source false

            puts "Found holding #{holding.id} for #{replace} and #{old_siglum}".yellow
        end
        # If the holding is not found a new one is created
        holding.paper_trail_event = "CH Migration modified holding" if holding
    end

    if !replace
        holding = Holding.new
        new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
        new_marc.load_source false
    else

    end

    # Kill old 852s
    new_marc.each_by_tag("852") {|t2| t2.destroy_yourself}

    if !only_group
        # Migrate 852 to 588
        if count_marc_tag(marc, "852") > 0
            a852 = fetch_single_subtag(marc.first_occurance("852"), "a")
            c852 = fetch_single_subtag(marc.first_occurance("852"), "c")
            insert_single_marc_tag(marc, "588", "a", "#{a852} #{c852}")
        end

        # Here we manage a full record with only 1 material group
        copy_tag(marc, new_marc, "300")
        
        copy_tag(marc, new_marc, "506")
        copy_tag(marc, new_marc, "541")
        copy_tag(marc, new_marc, "561")
        copy_tag(marc, new_marc, "563")
        copy_tag(marc, new_marc, "591")
        copy_tag(marc, new_marc, "592")

        move_tag_with_subtag(marc, new_marc, "700", "4", "fmo")
        move_tag_with_subtag(marc, new_marc, "700", "4", "scr")
        move_tag_with_subtag(marc, new_marc, "700", "4", "dpt")

        move_tag_with_subtag(marc, new_marc, "710", "4", "fmo")
        move_tag_with_subtag(marc, new_marc, "710", "4", "scr")
        move_tag_with_subtag(marc, new_marc, "710", "4", "dpt")

        copy_tag(marc, new_marc, "852")
        copy_tag(marc, new_marc, "856")

        # Copy the 590s, after the 852 is created
        marc.each_by_tag("590") {|tgs| migrate_590(new_marc, tgs)}

        # Remove the tags in the old marc
        remove_marc_tag(marc, "506")
        remove_marc_tag(marc, "541")
        remove_marc_tag(marc, "561")
        remove_marc_tag(marc, "563")
        remove_marc_tag(marc, "591")
        remove_marc_tag(marc, "592")
        remove_marc_tag(marc, "852")
        remove_marc_tag(marc, "856")

        # "conditional" tags, on the hardcoded side
        move_or_not_tag(marc, new_marc, "500", row[:o])
        move_or_not_tag(marc, new_marc, "691", row[:s])
    else
        # in this case we move only the indicated group
        copy_tag(marc, new_marc, "852")
        copy_group(marc, new_marc, only_group)
        delete_group(marc, only_group)
    end

    # As a last goodie, remove alle the remaining $8 that could be there
    new_marc.all_tags.each do |tag|
        tag.each_by_tag("8") {|the8| the8.destroy_yourself}
    end


    # Insert the 500 note, only if Z is filled
    # or if this is a result of a split
    insert_single_marc_tag(new_marc, "500", "a", row[:ac]) if row[:z] || row[:w].include?("split")
    
    ## Add the "additional group" notes
    if additional_notes
        if additional_notes[:"note500"]
            additional_notes[:"note500"].each do |note|
                insert_single_marc_tag(new_marc, "500", "a", "Additional material group: " + note)
            end
        end

        if additional_notes[:"note599"]
            insert_single_marc_tag(new_marc, "599", "a", "Deleted groups: " + additional_notes[:"note599"])
        end
    end

    # Save the holding
    new_marc.suppress_scaffold_links
    new_marc.import
    
    holding.marc = new_marc
    holding.source = source
    
    holding.suppress_reindex
    
    #begin
      holding.save
      puts "Saved holding #{holding.id}"
    #rescue => e
    #  $stderr.puts"Could not save holding record for #{source.id}"
    #  $stderr.puts e.message.blue
    #end

end

def tag_migrate_collection_and_sigle_item(row, source, marc)
    #rename_marc_tag(marc, "598", "594")
    remove_marc_tag(marc, "740")
    remove_marc_tag(marc, "852")
end

## FIXME
## MIGRATION OF 594
## if run two times, 594 is deleted
def tag_migrate_child_ms(marc)
    remove_marc_tag(marc, "506")
    remove_marc_tag(marc, "525")
    remove_marc_tag(marc, "541")
    remove_marc_tag(marc, "561")
    remove_marc_tag(marc, "563")
    remove_marc_tag(marc, "591")
    remove_marc_tag(marc, "592")
    ##remove_marc_tag(marc, "594")
    remove_marc_tag(marc, "651")
    remove_marc_tag(marc, "852")
    remove_marc_tag(marc, "856")
    remove_marc_tag(marc, "740")

    ##rename_marc_tag(marc, "598", "594")
end

def migrate_children(source, new_id = false, purge_groups = false)

    source.child_sources.each do |child_link|
        child = Source.find(child_link.id)
        child.marc.load_source(false)

        if new_id
            # Swap to the new record
            # This is when a record changes ID
            child.source_id = new_id
            w773 = child.marc.first_occurance("773").fetch_first_by_tag("w")
            w773.content = new_id
        end
        # DO NOT create the group note for children, but delete the group!
        if purge_groups
            purge_groups.each do |grp|
                delete_group(child.marc, grp)
            end
        end

        # Migrate the tags only if it was not already migrated
        tag_migrate_child_ms(child.marc) if child.record_type != 3

        # Still save, because it could be for a 773 update
        child.marc.import

        child.suppress_reindex
        child.suppress_update_count
        child.suppress_update_77x
        if new_id
            child.paper_trail_event = "CH Migration parent #{source.id} to #{new_id}"
            puts "Saving child #{child.id}, 773 from #{source.id} to #{new_id}".yellow
        else
            child.paper_trail_event = "CH Migration child record update"
            puts "Saving child #{child.id}".yellow
        end
        child.record_type = 3
        child.save
        child = nil
    end

end


def migrate(row, s, holding_note = nil)
    puts "Migrating #{s.id}".green
    create_holding(row, s, s.marc, nil, nil, nil, holding_note)

    tag_migrate_collection_and_sigle_item(row, s, s.marc)
    s.record_type = 8

    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x
    s.paper_trail_event = "CH Migration migrated record"
    s.save

    # Migrate the children too
    migrate_children(s)

end

def merge(row, s, note, do_merge = true)
    replace_holding = false
    preserve_510 = []

    # Force a reload
    s = Source.find(s.id)

    # Is there an EXISTING holding?
    # We pull the data from CH into
    # that holding
    if row[:z] != nil
        replace_holding = row[:z] 
    end

    # We need the new id, in AB
    begin
        a1_rec = Source.find(row[:ab])
    rescue ActiveRecord::RecordNotFound
        puts "NOT found #{row[:d]}".red
        return
    end

    puts "old: #{s.id} new: #{a1_rec.id} " + (do_merge ? "merged" : "")

    # THEN we overwrite the contents with our record
    # This is only for records that are merged
    # For the others (deleted), we keep the contents
    if do_merge
        # Preserve 510
        # This is ultra tricky, as we cannot load
        # The source two times
        a1_rec_safe_copy = Source.find(a1_rec.id)
        a1_rec_safe_copy.marc.load_source false # We do not need the links
        a1_rec_safe_copy.marc.each_by_tag("510") do |tag|
            preserve_510 << tag.deep_copy
        end

        # Move the source, note that
        # Marc source in a1_res is still unloaded
        a1_rec.marc_source = s.marc_source
    end

    old_record_type = s.record_type
    old_siglum = s.lib_siglum
    # ok now load the ource
    a1_rec.marc.load_source true
    a1_rec.marc.set_id(a1_rec.id) # Make sure the 001 field is always updated

    # When merging, pull the data from the "new" source
    if do_merge
        create_holding(row, a1_rec, a1_rec.marc, replace_holding, old_siglum, nil, note)
    else
        # When deleting, use the old source as ref
        # But attach the holdings to the BM record!
        create_holding(row, a1_rec, s.marc, replace_holding, old_siglum, nil, note)
    end

    # If we have a parent MS, we need to update the 774
    # in there, and update our source_id
    update_parent_ms(s.marc, s, a1_rec)

    # Before deleting, we should fix the child records
    migrate_children(s, a1_rec.id)

    # Delete the old record always
    # When "merge" the contents are
    # preserved into the BM one
    s.delete

    # If we are merging, migrate the tags
    # And then save
    if do_merge
        tag_migrate_collection_and_sigle_item(row, a1_rec, a1_rec.marc) 
    end

    # Move back the 510
    if preserve_510.count > 0
        # Purge eventual old 510s
        remove_marc_tag(a1_rec.marc, "510")

        preserve_510.each do |tag|
            a1_rec.marc.root.children.insert(a1_rec.marc.get_insert_position("510"), tag)
        end
    end

    puts "Saving #{a1_rec.id}".blue

    # Insert the 500 note in the BM record, for merge
    insert_single_marc_tag(a1_rec.marc, "500", "a", row[:ac]) if do_merge # Merge case
    insert_single_marc_tag(a1_rec.marc, "500", "a", "This record replaces #{s.id}") if !do_merge #Delete case

    a1_rec.suppress_reindex
    a1_rec.suppress_update_count
    a1_rec.suppress_update_77x
    a1_rec.paper_trail_event = "CH Migration merged record"
    a1_rec.save
end

# Delete removes the old ch source
# but before that makes holdings with it
# and attaches them to thr BM Source
# KEEPING THE CONTENTS OF THE BM SOURCE
def delete(row, s, note)
    merge(row, s, note, false)
end

# Purge removes selected groups from the record
def purge(row, s)
    groups = []
    result_note = {}

    if row[:y] == nil
        puts "#{s.id} purge no group id!".red
        return
    end

    if row[:y].include?(",")
        groups = row[:y].split(",").map {|id| id.gsub("'","").to_i}
    else
        groups << row[:y].gsub("'","").to_i
    end

    groups.each {|g| puts "#{s.id} invalid group #{g}".red if g < 1}

    note = ["593", "260", "300", "590"].map do |tag|
        tag_to_text(s.marc, tag, groups)
    end.compact.join("\n")

    groups.each do |grp|
        human_note =  groups_to_human_readable_text(s.marc, format('%02d', grp).to_str)
        result_note[:"note500"] = [] if !result_note.include?(:"note500")
        result_note[:"note500"] << human_note
        #insert_single_marc_tag(s.marc, "500", "a", "Additional material group: " + human_note)

        delete_group(s.marc, grp)
    end

    # As above non human readable one in 599
    result_note[:"note599"] = note
    #insert_single_marc_tag(s.marc, "599", "a", "Deleted groups: " + note)

    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x
    s.paper_trail_event = "CH Migration purged groups"
    s.save

    puts "Purged groups #{groups.to_s} in #{s.id}"

    # Also migrate the children and purge eventual groups
    migrate_children(s, false, groups)

    return result_note
end

# Split moves the group to a holding record
def split(row, s)
    replace = nil
    a1_rec = nil

    if row[:x] == nil
        puts "#{s.id} split no group id!".red
        return
    end

    group = row[:x].gsub("'","").to_i
    
    # Replace an existing holding?
    if row[:z] != nil
        replace = row[:z] 
    end

    # We need the new id, in AB
    begin
        a1_rec = Source.find(row[:ab])
    rescue ActiveRecord::RecordNotFound
        puts "NOT found #{row[:d]}".red
        return
    end

    puts "Splitting #{s.id} to #{a1_rec.id}"

    # We transform the group into a holding
    # In this case, it is an existing holding
    # to find it we need the source id (in replace)
    # and the lib siglum
    # if replace is nil, it will just add a new holding to the record
    # This call also deletes the group from the old CH record
    create_holding(row, a1_rec, s.marc, replace, s.lib_siglum, group)

    # Save the a1 record
    insert_single_marc_tag(a1_rec.marc, "500", "a", row[:ac])

    a1_rec.suppress_reindex
    a1_rec.suppress_update_count
    a1_rec.suppress_update_77x
    a1_rec.paper_trail_event = "CH Migration added holding"
    a1_rec.save

    # Now save the CH record
    insert_single_marc_tag(s.marc, "500", "a", row[:ad]) #Comment for splitted
    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x
    s.paper_trail_event = "CH Migration split groups"
    s.save

    puts "split group #{group} from #{s.id} to #{a1_rec.id}".green
end

[403005228, 402003262, 410003035, 407002601, 
 408002157, 400111321, 408000451, 400102496, 
 400102503, 400101502, 410000687, 408001320,
 410000725, 408002496, 402006544, 410002229,
 401001179].each do |q|
    z = Source.find(q)
    z.marc.load_source(false)
    z.marc.import

    z.suppress_reindex
    z.suppress_update_count
    z.suppress_update_77x

    z.save
end
test_array = []
CSV::foreach("housekeeping/upgrade_ch/migrate_ms.csv", quote_char: '~', col_sep: "\t", headers: headers) do |r|
    next if !r[:w]

    next if r[:w].include? "man."

    #next if r[:d] != "400108662" #&& r[:d] != "410002263"
    
    #next if r[:d] == "400108729"

    begin
        s = Source.find(r[:d])
    rescue ActiveRecord::RecordNotFound
        puts "not found #{r[:d]}"
        next
    end

    # Import the source in the system
	s.marc.load_source(false)
	s.marc.import

    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x
    s.paper_trail_event = "CH Migration link authority files"
    s.save

    case r[:w].strip
    when "migrate"
        migrate(r, s)
    when "merge"
        merge(r, s, nil)
    when "delete"
        delete(r, s, nil)
    when "purge"
        purge(r, s)
    when"purge, migrate"
        note = purge(r, s)
        migrate(r, s, note)
    when "purge, delete"
        note = purge(r, s)
        delete(r, s, note)
    when "purge, merge"
        note = purge(r, s)
        merge(r, s, note)
    when "split"
        split(r, s)
    when "split, migrate"
        split(r, s)
        migrate(r, s)
    else
        puts "WHAT IS #{r[:w]}".purple
    end
end

ap test_array.sort.uniq