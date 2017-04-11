Source.find_in_batches do |batch|
  batch.each do |s|

		next if s.source_id != nil

		s.marc.load_source false
    # IF none we do not care
    next if s.marc.by_tags("033").count == 0
  
    #puts "#{s.id}\t\t"
    
    all_dates = []
    
    s.marc.each_by_tag("033") do |t|
      
      t.each_by_tag("a") do |t|
        dates033 = []
        next if !t || !t.content
        
        # 033s can be like "12345678, 12345678)"
        toks = t.content.split(",")
        toks.each do |date_part|
          dates = date_part.strip
          
          if dates.length < 4
            puts "error date len < 4 #{dates}, #{s.id}"
            next
          end
          
          if dates.length >= 4 && dates.length < 12
            year1 = dates[0, 4]
            dates033 << year1 if year1.match(/^\d{4}$/)
          end
          
          if dates.length >=12
            year1 = dates[0, 4]
            dates033 << year1 if year1.match(/^\d{4}$/)
            
            #puts dates.red
            dates[8, dates.length - 1].split("-").each do |moredate|
              #puts moredate.green
              next if moredate == ""
              next if moredate.length < 4
              year2 = moredate[0, 4]
              dates033 << year2 if year2.match(/^\d{4}$/)
              #puts year2.yellow
            end
          end
          
        end
        
        #puts "#{t.content}\t#{dates033.join("\t")}" if dates033.count > 0
        #puts "#{t.content}\tERROR" if dates033.count == 0
        
        all_dates.concat(dates033)
        
      end
    end
    
    if all_dates.count == 0
      puts "#{s.id}\tNOT PARSABLE"
      next
    end
    
    # Search in the marc record
    m = s.marc
    m.by_tags("033").each {|t| t.destroy_yourself}
    
    user = s.user != nil ? s.user.name : "not set"
    
		tag260 = s.marc.root.fetch_all_by_tag("260")
		
		tagc = tag260.map {|t| t.fetch_all_by_tag("c").count}
		tagc = tagc.reduce(0, :+)

    marc_s = m.to_marc
    puts "MAMME" if marc_s == nil
    all_dates.each do |d|
      found =  marc_s.include?(d)
      puts "#{s.id}\t#{d}\t#{s.lib_siglum}\t#{user}\t260: #{tag260.count}\tc: #{tagc}" if !found
    end
    
  end
end