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
    marc.root.children.insert(s.marc.get_insert_position(tag), new_tag)
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

def create_holding(row, source, marc)    
    holding = Holding.new
    new_marc = MarcHolding.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/holding/default.marc"))
    new_marc.load_source false

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
    copy_tag(marc, new_marc, "773", "973")

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

def tag_migrate_collection(row, source, marc)
    rename_marc_tag(marc, "598", "594")
    remove_marc_tag(marc, "852")
end

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

def migrate(row, s)

    create_holding(row, source, marc)

    if s.record_type == 1
        tag_migrate_collection(row, s, s.marc)
    elsif s.record_type == 2
        tag_migrate_ms(row, s, s.marc)
    else
        puts s.record_type
    end

    source.record_type = 8

    source.suppress_reindex
    source.suppress_update_count
    source.suppress_update_77x

    source.save

end

def merge(row, s)

    # Force a reload
    s = Source.find(s.id)

    ## TODO
    if row[:z] != nil
        "Puts find holding"
        return
    end

    # We need the new id, in AB
    a1_rec = Source.find(row[:ab])

    puts "old: #{s.id} new: #{a1_rec.id}"

    # THEN we overwrite the contents with our record
    a1_rec.marc_source = s.marc_source
    old_record_type = s.record_type
    # Delete the old record
    s.delete
    # ok now load the ource
    a1_rec.marc.load_source true

    create_holding(row, a1_rec, a1_rec.marc)    

    # Migrate the tags
    if old_record_type == 1
        tag_migrate_collection(row, a1_rec, a1_rec.marc)
    elsif old_record_type == 2
        tag_migrate_ms(row, a1_rec, a1_rec.marc)
    else
        puts s.record_type
    end

    # Insert the 500 note
    insert_single_marc_tag(a1_rec, "500", "a", row[:ac])

    a1_rec.suppress_reindex
    a1_rec.suppress_update_count
    a1_rec.suppress_update_77x
    a1_rec.save

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
        #migrate(r, s)
    elsif r[:w] == "merge"
        merge(r, s)
    end
end


