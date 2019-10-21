## There is no C column!!!!!
headers = [:a, :b, :c, :d, :e, :f, :g, :h, :i, :j, :k, :l, :m, :n, :o, :p, :q, :r, :s, :t, :u, :v, :w, :x, :y, :z, :aa, :ab, :ac, :ad, :ae, :af]

items = []


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
    marctag.add_at(MarcNode.new("source", "0", value, nil), 0)
    marctag.sort_alphabetically
end

def insert_single_marc_tag(marc, tag, subtag, value)
    new_tag = MarcNode.new("source", tag, "", "##")
    new_tag.add_at(MarcNode.new("source", subtag, value, nil), 0)
    new_tag.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position(tag), new_tag)
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

def copy_group(marc, new_marc, group)
    marc.all_tags.each do |tgs|
        grp = tgs.fetch_first_by_tag("8")
        next if !grp || !grp.content

        if grp.content.to_i == group
            copy_tag(marc, new_marc. tgs.tag)
        end
    end
end

def delete_group(marc, group)
    marc.all_tags.each do |tgs|
        grp = tgs.fetch_first_by_tag("8")
        next if !grp || !grp.content

        if grp.content.to_i == group
            tgs.destroy_yourself
        end
    end
end

def create_holding(row, source, marc, replace = nil, old_siglum = nil, only_group = nil)
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
        # Here we manage a full record with only 1 material group
        copy_tag(marc, new_marc, "300")
        copy_tag(marc, new_marc, "500")
        copy_tag(marc, new_marc, "505", "500")
        copy_tag(marc, new_marc, "506")
        copy_tag(marc, new_marc, "541")
        copy_tag(marc, new_marc, "561")
        copy_tag(marc, new_marc, "563")
        copy_tag(marc, new_marc, "591")
        copy_tag(marc, new_marc, "592")
        ## CHECK
        copy_tag(marc, new_marc, "700")
        copy_tag(marc, new_marc, "710")
        ## !!!!!! check
        ##copy_tag(marc, new_marc, "773", "973")

        copy_tag(marc, new_marc, "852")
        copy_tag(marc, new_marc, "856")


        # Remove the tags in the old marc
        remove_marc_tag(marc, "300")
        remove_marc_tag(marc, "500")
        remove_marc_tag(marc, "505")
        remove_marc_tag(marc, "506")
        remove_marc_tag(marc, "541")
        remove_marc_tag(marc, "561")
        remove_marc_tag(marc, "563")
        remove_marc_tag(marc, "591")
        remove_marc_tag(marc, "592")
        remove_marc_tag(marc, "852")
        remove_marc_tag(marc, "856")
    else
        # in this case we move only the indicated group
        copy_group(marc, new_marc, only_group)
        delete_group(marc, only_group)
    end

    # Insert the 500 note
    insert_single_marc_tag(new_marc, "500", "a", row[:ac])

    # Save the holding
    new_marc.suppress_scaffold_links
    new_marc.import
    
    holding.marc = new_marc
    holding.source = source
    
    holding.suppress_reindex
    
    begin
      holding.save
      puts "Saved holding #{holding.id}"
    rescue => e
      $stderr.puts"Could not save holding record for #{source.id}"
      $stderr.puts e.message.blue
    end

end

def tag_migrate_collection_and_sigle_item(row, source, marc)
    rename_marc_tag(marc, "598", "594")
    remove_marc_tag(marc, "852")
end

=begin
NOT USED, for edition_content
def tag_migrate_ms(row, source, marc)
    remove_marc_tag(marc, "506")
    remove_marc_tag(marc, "525")
    remove_marc_tag(marc, "541")
    remove_marc_tag(marc, "561")
    remove_marc_tag(marc, "563")
    remove_marc_tag(marc, "591")
    remove_marc_tag(marc, "592")
    remove_marc_tag(marc, "594")
    remove_marc_tag(marc, "651")
    remove_marc_tag(marc, "852")
    remove_marc_tag(marc, "856")
    remove_marc_tag(marc, "740")

    rename_marc_tag(marc, "598", "594")
end
=end

def migrate(row, s)

    create_holding(row, s, s.marc)

    tag_migrate_collection_and_sigle_item(row, s, s.marc)

    # Insert the 500 note
    insert_single_marc_tag(s.marc, "500", "a", row[:ac])

    s.record_type = 8

    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x

    s.save

end

def merge(row, s, overwrite_source = true)
    replace = false

    # Force a reload
    s = Source.find(s.id)

    ## TODO
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

    puts "old: #{s.id} new: #{a1_rec.id} " + (overwrite_source ? "merged" : "")

    # THEN we overwrite the contents with our record
    # This is only for records that are merged
    # For the others (deleted), we keep the contents
    a1_rec.marc_source = s.marc_source if overwrite_source

    old_record_type = s.record_type
    old_siglum = s.lib_siglum
    # ok now load the ource
    a1_rec.marc.load_source true

    # When merging, pull the data from the "new" source
    if overwrite_source
        create_holding(row, a1_rec, a1_rec.marc, replace, old_siglum)
    else
        # When deleting, use the old source as ref
        create_holding(row, a1_rec, s.marc, replace, old_siglum)
    end

    # Delete the old record
    s.delete

    # If we are merging, migrate the tags
    # And then save
    if overwrite_source
        puts "Saving #{a1_rec.id}".blue
        # Migrate the tags, if merging
        tag_migrate_collection_and_sigle_item(row, a1_rec, a1_rec.marc) 

        # Insert the 500 note, only for merging
        insert_single_marc_tag(a1_rec.marc, "500", "a", row[:ac]) 

        a1_rec.suppress_reindex
        a1_rec.suppress_update_count
        a1_rec.suppress_update_77x
        a1_rec.save
    end

end

# Delete removes the old ch source
# but before that makes holdings with it
# and attaches them to thr BM Source
# KEEPING THE CONTENTS OF THE BM SOURCE
def delete(row, s)
    merge(row, s, false)
end

# Purge removes selected groups from the record
def purge(row, s)
    groups = []

    if row[:y] == nil
        puts "#{s.id} purge no group id!".red
        return
    end

    if row[:y].include?(",")
        groups = row[:y].split(",").map {|id| id.to_i}
    else
        groups << row[:y].to_i
    end

    groups.each {|g| puts "#{s.id} invalid group #{g}".red if g < 1}

    note = ["593", "260", "300", "590"].map do |tag|
        tag_to_text(s.marc, tag, groups)
    end.compact.join("\n")

    groups.each do |grp|
        delete_group(s.marc, grp)
    end

    # Add the note in the 500
    insert_single_marc_tag(s.marc, "500", "a", "Additional material group(s): " + note)

    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x

    s.save

    puts "Purged groups #{groups.to_s} in #{s.id}"

end

# Split moves the group to a holding record
def split(row, s)
    replace = nil
    a1_rec = nil

    if row[:x] == nil
        puts "#{s.id} split no group id!".red
        return
    end

    group = row[:y].to_i
    
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
    a1_rec.save

    # Now save the CH record
    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x

    s.save

    puts "split group #{group} from #{s.id} to #{a1_rec.id}".green
end

[403005228, 402003262, 410003035, 407002601, 
 408002157, 400111321, 408000451, 400102496, 
 400102503, 400101502, 410000687, 408001320,
 410000725].each do |q|
    z = Source.find(q)
    z.marc.load_source(false)
    z.marc.import

    z.suppress_reindex
    z.suppress_update_count
    z.suppress_update_77x

    z.save
end

CSV::foreach("migrate_ms.csv", quote_char: '~', col_sep: "\t", headers: headers) do |r|
    next if !r[:w]

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

    s.save

    if r[:w] == "migrate"
        #migrate(r, s)
    elsif r[:w] == "merge"
        #merge(r, s)
    elsif r[:w] == "delete"
        #delete(r, s)
    elsif r[:w] == "purge"
        #purge(r, s)
    elsif r[:w] == "purge, migrate"
        #purge(r, s)
        #migrate(r, s)
    elsif r[:w] == "purge, delete"
        #purge(r, s)
        #delete(r, s)
    elsif r[:w] == "purge, merge"
        #purge(r, s)
        #merge(r, s)
    elsif r[:w] == "split"
        split(r, s)
    else
        puts "WHAT IS #{r[:w]}".purple
    end
end