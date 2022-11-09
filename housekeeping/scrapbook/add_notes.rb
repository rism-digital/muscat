def insert_single_marc_tag(marc, tag, subtag, value)
    new_tag = MarcNode.new("source", tag, "", "##")
    new_tag.add_at(MarcNode.new("source", subtag, value, nil), 0)
    new_tag.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position(tag), new_tag)
end

l = YAML.load_file("notes_to_add.yml")

l.each do |id, notes|

    s = Source.find(id)
    s.marc.load_source

    notes[:note500].each do |n|
        insert_single_marc_tag(s.marc, "500", "a", "Additional material group: " + n)
    end

    insert_single_marc_tag(s.marc, "599", "a", "Deleted groups: " + notes[:note599])
    
    s.suppress_reindex
    s.suppress_update_count
    s.suppress_update_77x
    s.save
end