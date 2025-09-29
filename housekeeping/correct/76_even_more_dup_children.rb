excludes = %w(400100957
400101992
400102345
400102367
400102408
400102793
400103262
400104223
400104248
400107153
400108730
400108760
400108796
400108875
400108900
400109816
400109855
402003030
402003262
402003271
402003378
402003526
402003603
402003607
402003615
402004002
402004123
402004250
402004257
402004296
402004308
402006120
402006338
402006437
402006486
402007058
402008503
403007265
406001539
406001551
406001731
406002113
406003360
407000124
407000333
407000961
407001173
407001291
407002284
407002586
408000063
408000451
408001232
408002179
410002130)

Source.where("id > 400000000 and id < 420000000").each do |s|
    names = []
    notes = ""

    next if excludes.include?(s.id.to_s)

    s.marc.load_source true

    s.marc.each_by_tag("774") do |link|
        link_id = link.fetch_first_by_tag("w")
        link_type = link.fetch_first_by_tag("4")
        next if !link_id || !link_id.content
        holding_link = true if link_type && link_type.content && link_type.content == "holding"
        if holding_link
            holding = s.get_collection_holding(link_id.content.to_i)
            child = holding.source if holding && holding.source
        else
            child = s.get_child_source(link_id.content.to_i)
        end

        next if !child

        title = child.marc.first_occurance("240", "a")

        composer = child.composer ? child.composer : ""

        title = (title && title.content) ? title.content : child.std_title

        names << "#{composer} #{title}".strip.downcase
    end

    s.marc.each_by_tag("500") do |node|
        txt = node.fetch_first_by_tag("a").content rescue txt = "[none]"
        notes += "\t#{txt}"
    end

    notes.strip!

    #next if !notes.downcase.include?("This record replaces".downcase)

    dups = names.select { |e| names.count(e) > 1 }.uniq
    titles = dups.join("\t")

    puts "#{s.id}\t#{notes}#{titles}" if dups.count > 0

end