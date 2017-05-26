def join_values(tag, subtag, marc)
  values = []
  marc.by_tags(tag).each do |t|
    t.each_by_tag(subtag) do |st|
      next if !st || !st.content
      values << st.content
    end
  end
  values
end

puts "id\tcatalog\txml\tedit\tdate\tsiglum\tuser\t518$a\t541$d\t260$c\t500$a\t245$a\t246$a"
Source.find_in_batches do |batch|
  batch.each do |s|

		#next if s.source_id != nil

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
    
    a = []
    a << join_values("518", "a", m)
    a << join_values("541", "d", m)
    a << join_values("260", "c", m)
    a << join_values("500", "a", m)
    a << join_values("245", "a", m)
    a << join_values("246", "a", m)

    marc_s = m.to_marc
    puts "MAMME" if marc_s == nil
    
    all_dates.each do |d|
      found =  marc_s.include?(d)
      if !found
        #ap a
        link_catalog = "http://admin.rism-ch.org/catalog/#{s.id}"
        link_admin = "http://admin.rism-ch.org/admin/sources/#{s.id}.xml"
        link_edit = "http://admin.rism-ch.org/admin/sources/#{s.id}/edit"
        print "#{s.id}\t#{link_catalog}\t#{link_admin}\t#{link_edit}\t#{d}\t#{s.lib_siglum}\t#{user}"
        
        run = true
        count = 0
        while run == true

          print "\t" + (a[0].count-1 >= count ? a[0][count] : "x1")
          print "\t" + (a[1].count-1 >= count ? a[1][count] : "x2")
          print "\t" + (a[2].count-1 >= count ? a[2][count] : "x3")
          print "\t" + (a[3].count-1 >= count ? a[3][count] : "x4")
          print "\t" + (a[4].count-1 >= count ? a[4][count] : "x5")
          print "\t" + (a[5].count-1 >= count ? a[5][count] : "x6")
         
          #ap a[4][0]
          #ap count
          puts
          count += 1
         
          run = false if (count > a[0].count-1 && count > a[1].count-1 &&
                          count > a[2].count-1 && count > a[3].count-1 &&
                          count > a[4].count-1 && count > a[5].count-1)
                         
          print "\t\t\t\t\t"
         
        end
        
        puts
        
      end
    end
    
  end
end