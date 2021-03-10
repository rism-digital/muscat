Folder.find(464).folder_items.each do |fi| 
    
    new_tag = MarcNode.new("source", "500", "", "##")
    new_tag.add_at(MarcNode.new("source", "a", "Die historische Musikaliensammlung aus der Privatbibliothek Gugger ist heute verschollen.", nil), 0)
    new_tag.sort_alphabetically
    fi.item.marc.root.children.insert(marc.get_insert_position("500"), new_tag)

    fi.save

end