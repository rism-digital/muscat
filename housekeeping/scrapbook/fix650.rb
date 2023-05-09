def insert_single_marc_tag(marc, tag, subtag, value)

end

CSV::foreach("Fix650.csv") do |r|
    begin
        s = Source.find(r[0])
    rescue
        puts "not found #{r[0]}"
        next
    end

    term = r[1].strip

    term = "Fugues (inst.)" if term == "Fugues (instr.)"

    id = StandardTerm.find_by_term(term)
    if !id
        puts term
    end

    s.marc.load_source true
    marc = s.marc

    new_tag = MarcNode.new("source", "650", "", "07")
    new_tag.add_at(MarcNode.new("source", "a", term, nil), 0)
    new_tag.add_at(MarcNode.new("source", "0", id.id.to_s, nil), 0) if id
    new_tag.sort_alphabetically
    marc.root.children.insert(marc.get_insert_position("650"), new_tag)

    s.save
end