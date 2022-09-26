

CSV::foreach("fix593.csv", col_sep: "\t") do |r|
    s = Source.find(r[0])

    mc = MarcConfigCache.get_configuration("source")
    w774 = MarcNode.new("source", "593", "", mc.get_default_indicator("593"))
    w774.add_at(MarcNode.new("source", "a", r[1], nil), 0 )
    w774.add_at(MarcNode.new("source", "8", "01", nil), 0 )

    s.marc.root.add_at(w774, s.marc.get_insert_position("593") )

#puts s.marc.to_marc

    s.save
end
