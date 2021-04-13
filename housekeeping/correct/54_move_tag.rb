

Person.all.each do |p|
    found = false

    p.marc.load_source false

    p.marc.by_tags("500").each do |t|
        new_tag = t.deep_copy
        new_tag.tag = "700"
        p.marc.root.children.insert(p.marc.get_insert_position(new_tag.tag), new_tag)
        found = true
    end

    p.marc.by_tags("500").each {|t| t.destroy_yourself}

    p.save if found

end