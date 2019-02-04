def tag_printer(tag, marc)
  
  lines = []
  tgs = []
  
  marc.each_by_tag(tag) do |t|
    t.each do |tn|

      #next if !(tn && tn.content)
      
      next if tn.tag == "0"
      next if !tn.content || tn.content.empty?
      
      tgs << "$#{tn.tag} #{tn.content}"
    end
    
    lines << tgs.join(", ")
  end
  
  return lines.join("\n")
  
end

count = 0

Source.where(record_type: 1).each do |s|
  found = false
      
  s.marc.each_by_tag("593") do |t|
    t.fetch_all_by_tag("a").each do |tn|

      next if !(tn && tn.content)
      found = true if tn.content == "Print"
    end

  end
  
  next if !found
  
  if s.marc.has_tag?("773")
    next
  end
  
  count += 1
  
  lines = [s.id]
  ["100", "245", "260", "300", "500", "505", "691", "510", "596", "593"].each do |t|
    lines << "~" + tag_printer(t, s.marc) + "~"
  end
  
  puts lines.join("±")
  
  #break if count > 20
end

puts count