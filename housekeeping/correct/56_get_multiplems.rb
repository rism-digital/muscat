Source.where(record_type: 8).each do |s|
    next if s.holdings.count == 1
    next if !s.siglum_matches?("CH")

    sigls = s.holdings.collect {|h| h.lib_siglum.start_with?("CH") ? h.lib_siglum : next}.compact

    next if sigls.count < 2

    old_parents = {}
    s.child_sources.each do |cs|
        
        cs.versions.each do |v|
            if v.event.start_with?("CH Migration parent")
                t = v.event.split(" ")
                old_id = t[3]
                if !old_parents.keys.include?(old_id)
                    old_parents[old_id] = [cs.id] 
                else
                    old_parents[old_id] << cs.id
                end

                #puts "#{s.id} #{cs.id} #{v.event}"
            end
        end

    end

    if !old_parents.empty? && old_parents.count > 1
        #puts s.id
        #ap old_parents
        old_parents.each do |key, values|
            puts "#{s.id}\t#{key}"
            values.each do |child|
        #        puts "#{s.id}\t#{key}\t#{child}"
            end
        end
    end

end