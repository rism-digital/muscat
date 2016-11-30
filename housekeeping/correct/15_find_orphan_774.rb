Source.where(["record_type = ?", MarcSource::RECORD_TYPES[:collection]]).each do |sid|
  s = Source.find(sid)
  
  s.marc.load_source false
  s.marc.each_by_tag("774") do |t|
    id = t.fetch_first_by_tag("w")
    if !id || !id.content
      puts "#{s.id}: missing 744 $w"
      next
    end
    #ap s.child_sources.map {|a| a.id}
    if !s.child_sources.map {|a| a.id}.include?(id.content.to_i)
      
      begin
        child = Source.find(id.content.to_i)
      rescue
        child = nil
      end
      
      if !child
        puts "#{s.id}: child_source: #{id.content.to_i}, child does not exist"
      else
        
        child.marc.load_source false
        link_tag = child.marc.first_occurance("773")
        
        if !link_tag
          puts "#{s.id}: child_source: #{id.content.to_i}, child has no 773"
          next
        end
        
        link_id = link_tag.fetch_first_by_tag("w")
        
        if link_id && link_id.content
          if link_id.content.to_i == s.id
            puts "#{s.id}: child_source: #{id.content.to_i}, child 773 points to parent"
          else
            puts "#{s.id}: child_source: #{id.content.to_i}, child 773 points to #{link_id.content}"
          end
        else
          puts"#{s.id}: child_source: #{id.content.to_i}, child 773 malformed"
        end
        
      end
    end
  end
  
end