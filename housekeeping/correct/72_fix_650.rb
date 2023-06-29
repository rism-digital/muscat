pb = ProgressBar.new(74552) # wc -l is my friend

CSV::foreach("fixed_650.csv") do |line|

    pb.increment!

    s = Source.find(line[0])
    s.marc.load_source

    if s.marc.root.fetch_all_by_tag("650").size > 0
        puts "Record #{s.id} has at least 1 650"
        next
    end

    mc = MarcConfigCache.get_configuration("source")
    nt = MarcNode.new("source", "650", "", mc.get_default_indicator("650"))
    nt.add_at(MarcNode.new("source", "0", line[2].strip, nil), 0 )

    s.marc.root.add_at(nt, s.marc.get_insert_position("650") )

    s.suppress_update_77x

    s.paper_trail_event = "Add 650: #{line[1]}"

    s.save

end