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

def create_holding(row, source, marc, replace = nil, old_siglum = nil)
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
 #   s.delete

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
        migrate(r, s)
    elsif r[:w] == "merge"
        merge(r, s)
    elsif r[:w] == "delete"
        delete(r, s)
    end
end


