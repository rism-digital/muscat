

WorkNode.all.each do |s|
    
    s.marc.load_source false

    total = s.marc.by_tags("024")
    s.marc.by_tags("024").each do |t|
        tgs = t.fetch_first_by_tag("2")
        if tgs.content != "DNB"
            puts "#{s.id} delete #{tgs.content}"
            t.destroy_yourself if total.count > 1
            puts "#{s.id} SKIP #{tgs.content}" if total.count == 1
        end

        tgs = t.fetch_first_by_tag("a")
        if !tgs || !tgs.content || tgs.content.empty?
            puts "#{s.id} delete empty"
            t.destroy_yourself
        end
    end

    s.save
end



#puts all.sort.uniq