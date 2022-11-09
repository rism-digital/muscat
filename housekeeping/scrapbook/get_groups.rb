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



# Purge removes selected groups from the record
def purge(row, s)
    groups = []
    result_note = {}

    if row[1].include?(",")
        groups = row[1].split(",").map {|id| id.gsub("'","").to_i}
    else
        groups << row[1].gsub("'","").to_i
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

    end

    # As above non human readable one in 599
    result_note[:"note599"] = note
    #insert_single_marc_tag(s.marc, "599", "a", "Deleted groups: " + note)

    return result_note
end

output = {}

CSV::foreach("fix_group_note.tsv", col_sep: "\t") do |r|

        s = Source.find(r[0])
        output[r[0]] = purge(r, s)

end

puts output.to_yaml