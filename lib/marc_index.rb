module MarcIndex
  
  def marc_index_tag(conf_tag, conv_value, marc, model)
    
    out = []
    
    if conf_tag.length == 4
      tag = conf_tag[0..2]
      subtag = conf_tag[3]
      
      begin
        t = marc.first_occurance(tag, subtag)
        
        marc.each_by_tag(tag) do |marctag|
          marctag.each_by_tag(subtag) do |marcvalue|
            out << marcvalue.content if marcvalue.content
          end
        end
        
      rescue => e
        puts e.exception
        puts "Marc failed to load for #{model.to_yaml}, check foreign relations, data: #{tag}, #{subtag}"
      end
    end

    out
    
  end

end