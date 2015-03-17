Source.where("updated_at > '2015-01-29 00:00:00'").each do |s|
  
  begin
    marc = s.marc
    x = marc.to_marc
  rescue => e
    #puts e.exception
    next
  end
  
  modified = false
  
  marc.each_by_tag("033") do |t|
    
    a = t.fetch_all_by_tag("a")
     
    if t.indicator == "2#" && a.count < 2
      puts "#{s.id}, #{s.created_at} #{s.updated_at}"
      t.indicator = "0#"
      modified = true
    end
    
  end
  
  s.save! if modified
  
end