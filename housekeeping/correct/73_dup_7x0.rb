
def get_position_after(marc, tag)
    insert_at = 0
    for child in marc.root.children
        puts child
        puts tag
      break if child == tag
      insert_at += 1
    end
    insert_at
  end

def duplicate_7x0(marc, tag_nr, model)
    found = false
    
    marc.root.fetch_all_by_tag(tag_nr).each do |t|
        tgs = t.fetch_all_by_tag("4")
        next if tgs.count < 2

        # save the values, remove empty ones, reverse the array so we
        # get the elements in the proper order
        vals = tgs.each.map {|tt| tt.content.strip}.reject(&:empty?)

#        ap vals

        # destroy them
        t.fetch_all_by_tag("4").each {|tt| tt.destroy_yourself}

#        puts t

        #duplicate the tag
        tdups = []
        
        # create the new items
        # note it is count - 1 - 1 because we discard the current tag
        # If there was one empty and one filled with data, vals reject
        # the empty one so we can end up in the case that there are
        # no tags to add
        if vals.count > 1
            for i in 0..(vals.count - 2)
                tdups << t.deep_copy
            end
        end

        # Add the last val back to this tags
        t.add_at(MarcNode.new(model, "4", vals.pop, nil), 0 )
        t.sort_alphabetically

        # Now add it to the other items
        # tdups can be empty if the original one was
        # $4something$4
        last_tag = t
        tdups.each do |tdup|
            tdup.add_at(MarcNode.new(model, "4", vals.pop, nil), 0 )
            tdup.sort_alphabetically
            marc.root.add_at(tdup, get_position_after(marc, last_tag) )
            last_tag = tdup
        end

        found = true
    end
    
    if found then
        #p "----------------------"
        #p marc
    end

    return found
end

=begin
s  = Source.find(1001128606)
s.marc.load_source true

f = duplicate_7x0(s.marc, "700", "source")
f2 = duplicate_7x0(s.marc, "710", "source")

ap s.marc
=end

File.open("700_fixed.txt", "a") do |file|

pb = ProgressBar.new(Source.all.count)
Source.find_in_batches do |batch|

  batch.each do |s|
	
    s.marc.load_source true

    f = duplicate_7x0(s.marc, "700", "source")
    f2 = duplicate_7x0(s.marc, "710", "source")

    if f or f2
        file.puts("Source\t#{s.id}")
        s.paper_trail_event = "Split 700/710"
        s.save
    end

    pb.increment!

  end

end


pb = ProgressBar.new(Holding.all.count)
Holding.find_in_batches do |batch|

  batch.each do |s|
	
    s.marc.load_source true

    f = duplicate_7x0(s.marc, "700", "holding")
    f2 = duplicate_7x0(s.marc, "710", "holding")

    if f or f2
        file.puts("Holding\t#{s.id}")
        s.paper_trail_event = "Split 700/710"
        s.save
    end

    pb.increment!

  end

end

end #file log