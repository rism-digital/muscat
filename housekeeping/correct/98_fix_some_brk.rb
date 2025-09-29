all = []
#pb = ProgressBar.new(Source.all.count)
mc = MarcConfigCache.get_configuration("source")

Source.where("marc_source LIKE '%{{brk}}%'").each do |s|

    save = false
    s.marc.load_source true

    s.marc.each_by_tag("031") do |tt|
      new_fld = []
      tgs = tt.fetch_all_by_tag("q")
      tgs.each do |t|
        if t&.content&.include?("{{brk}}")
          new_fld = t.content.split("{{brk}}")
          t.destroy_yourself
        end
      end

      new_fld.reverse_each do |nf|
        tt.add_at(MarcNode.new("source", "q", nf.strip, nil), 0 )
        save = true
      end
      tt.sort_alphabetically if new_fld.count > 0
    end

    new563 = []
    all563 = s.marc.by_tags("563")
    all563.each do |tt|
        t = tt.fetch_first_by_tag("a")
        grp = tt.fetch_first_by_tag("8")
        if t&.content&.include?("{{brk}}")
            new563 = t.content.split("{{brk}}")
        end

        if new563.count > 0
            tt.destroy_yourself
            save = true
            new563.each do |new_tag|
                a563 = MarcNode.new("source", "563", "", mc.get_default_indicator("563"))
    
                a563.add_at(MarcNode.new("source", "a", new_tag, nil), 0 )
                a563.add_at(MarcNode.new("source", "8", grp.content, nil), 0 )
                a563.sort_alphabetically
                s.marc.root.add_at(a563, s.marc.get_insert_position("563") )
            end
        end

    end



    #pb.increment!
    s.paper_trail_event = "Remove {{brk}} from 031 and 563"
    s.save if save

end

#puts all.sort.uniq