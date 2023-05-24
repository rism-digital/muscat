def duplicate_7x0(marc, tag_nr, model)
    found = false
    
    marc.root.fetch_all_by_tag(tag_nr).each do |t|
        tgs = t.fetch_all_by_tag("4")
        next if tgs.count < 2

        # save the values
        vals = tgs.each.map {|tt| tt.content}

#        ap vals

        # destroy them
        t.fetch_all_by_tag("4").each {|tt| tt.destroy_yourself}

#        puts t

        #duplicate the tag
        tdups = []
        
        # create the new items
        # note it is count - 1 - 1 because we discard the current tag
        for i in 0..(vals.count - 2)
            tdups << t.deep_copy
        end

        # Add the last val back to this tags
        t.add_at(MarcNode.new(model, "4", vals.pop, nil), 0 )
        t.sort_alphabetically

        # Now add it to the other items
        tdups.each do |tdup|
            tdup.add_at(MarcNode.new(model, "4", vals.pop, nil), 0 )
            tdup.sort_alphabetically
            marc.root.add_at(tdup, marc.get_insert_position(tag_nr) )
        end

        found = true
    end
    
    if found then
        #p "----------------------"
        #p marc
    end

    return found
end

all = []
=begin
pb = ProgressBar.new(Source.all.count)
Source.find_in_batches do |batch|

  batch.each do |s|
	
    s.marc.load_source true

    f = duplicate_7x0(s.marc, "700", "source")
    f2 = duplicate_7x0(s.marc, "710", "source")

    s.save if f or f2

    pb.increment!

  end

end
=end

#pb = ProgressBar.new(Holding.all.count)
Holding.find_in_batches do |batch|

  batch.each do |s|
	
    s.marc.load_source true

    f = duplicate_7x0(s.marc, "700", "holding")
    f2 = duplicate_7x0(s.marc, "710", "holding")

    if f or f2
        puts s.id
        s.save
    end

    pb.increment!

  end

end