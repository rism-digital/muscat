File.open("housekeeping/scrapbook/protypen_fix.txt") do |f|
    f.each_line do |line|
        id, tag, thing, word, correction, more_correction = line.split("\t")

        if word == correction && more_correction == "\n"
            puts word
            next
        end

        next if more_correction == "skip"

        #correction = more_correction if more_correction != "\n"

        s = Source.find(id)
        s.marc_source.gsub!(word, correction)
        s.paper_trail_event = "Fix protypen #{word} with #{correction}"
        s.save
    end

end