def delete_single_subtag(marctag, subtag)
    st = marctag.fetch_first_by_tag(subtag)
    st.destroy_yourself if st
end

def do_the_thing(marc, type = "source")
    t = marc.first_occurance("852")
    delete_single_subtag(t, "b")
    delete_single_subtag(t, "z")
    t.add_at(MarcNode.new(type, "b", "Swiss Literary Archives (SLA)", nil), 0)
    t.add_at(MarcNode.new(type, "z", "Estate of Gottfried von Fellenberg", nil), 0)
    t.sort_alphabetically

    new_541 = MarcNode.new(type, "541", "", "1#")
    new_541.add_at(MarcNode.new("institution", "c", "Donation", nil), 0)
    new_541.add_at(MarcNode.new(type, "a", "The Fellenberg family represented by Theodor and Walter von Fellenberg", nil), 0)
    new_541.add_at(MarcNode.new(type, "d", "1945", nil), 0)
    new_541.sort_alphabetically
    marc.root.add_at(new_541, marc.get_insert_position("541"))

    ap marc
end

srcs = []

Source.where("shelf_mark LIKE '%SNL-Musik-Fell-%'").each do |s|
    do_the_thing(s.marc)
    s.save
    srcs << s
end

Holding.where("marc_source LIKE '%SNL-Musik-Fell-%'").each do |s|

    t = s.marc.first_occurance("852")
    st = t.fetch_first_by_tag("c")

    if st && st.content && st.content.include?("SNL-Musik-Fell")
        do_the_thing(s.marc, "holding")
    end

    s.save
    srcs << s.source
end

f = Folder.new(:name => "Fellenberg Sources", :folder_type => "Source", wf_owner: 97)
f.save
f.add_items(srcs)