pb = ProgressBar.new(4195) ## ok ok I know...

CSV::foreach("housekeeping/upgrade_ch/rewrite_titles.csv") do |title|

    std_title_id = title[0].to_i
    old_title = title[2]
    new_title = title[3]
    to_downcase = title[4]
    rewrite = title[5]

    if to_downcase != nil
        toks = old_title.split(",")
        toks[0][0] = toks[0][0].downcase

        if toks[1].include?("'")
            new_title = toks[1].strip + toks[0].strip
        else
            new_title = toks[1].strip + " " + toks[0].strip
        end


    end

    new_title = rewrite if rewrite

    t = StandardTitle.find(std_title_id)
    t.title = new_title
    t.title_d = new_title.downcase

    t.suppress_reindex
    t.save

    t.referring_sources.each do |s|
        #puts s.id
        s.suppress_reindex
        s.suppress_update_count
        s.suppress_update_77x
        s.paper_trail_event = "Fixed title #{old_title}: #{new_title}"
        s.save
    end

    pb.increment!
end