f = Folder.find(488)

f.folder_items.each do |i|
    #puts i.item.id
    next if !i.item

    #puts i.id
    #puts i.item.class

    allr = %w(digital_object_links
    digital_objects
    referring_sources
    referring_people
    referring_publications
    people
    publications
    standard_terms
    referring_holdings
    delayed_jobs
    workgroups
    institutions
    referring_institutions)

    #no places

    allr.each do |r|
    
        m = i.item.send(r)
        if m.count != 0
            puts "#{i.item.id} #{r} #{m.count}"
        end
    end

end
