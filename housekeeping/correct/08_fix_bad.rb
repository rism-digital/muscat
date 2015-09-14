records = [400219385, 400219386, 400219387, 400219388, 402000852, 402001625, 402007022, 402011093, 404000382, 404000449, 404000460, 404000476, 404000491, 404000492, 405000905, 405000908, 405000915, 406000042, 406000043, 406000044, 406000045, 406000046, 406000047, 406000048, 406000049, 406000050, 406000067, 406000068, 406000069, 406000070, 406000071, 406000072, 406000073, 406000074, 406000075, 406000076, 406000120, 406000179, 406000180, 406000181, 406000182, 406000183, 406000184, 406000185, 406000186, 406000187, 406000188, 406000189, 406000190, 406000191, 406000192, 406000193, 406000194, 406000195, 406000196, 406000197, 406000198, 406000199, 406000200, 406000201, 406000202, 406000203, 406000204, 406000205, 406000211, 406000263, 406000264, 406000265, 406000266, 406000829, 406000830, 406000831, 406000832, 406000833, 406000834, 408000193, 408000194, 408000195, 408000196, 408000197, 408000198, 408000199, 408000267, 408001980, 408002011, 408002042, 408004026, 408004408, 408005013, 408005062, 408005258, 409000049, 409000053]


records.each do |r|
  source = Source.find(r)
  
  begin
    # hey it worked!
    puts source.marc
    next
  rescue => e
    message = e.exception.message
  end

  new_marc = MarcSource.new(source.marc_source)
  new_marc.load_source(false)
  
  #puts new_marc.to_marc

  contents = message.split("=")
  if contents.count > 0
    #puts contents[1]
    
    subtags = {} 
    
    if "=#{contents[1]}" =~ Regexp.new('^[\=]([\d]{3,3})[\s]+(.*)$')
     # puts $1, $2
      data = $2
      parsed_tag = $1
      
      indicator = nil
      if data =~ /^[\s]*([^$]*)([$].*)$/
        indicator = $1
        record = $2
      end
      
      # iterate trough the subfields
      while record =~ /^[$]([\d\w]{1,1})([^$]*)(.*)$/
        subtag  = $1
        content = $2
        record  = $3
        
        subtags[subtag] =  content
      end
      
      # we have the non working tag
      # process marc and fix it
      
      new_marc.each_by_tag(parsed_tag) do |t|
        
        master = t.fetch_first_by_tag("0")
        next if master && master.content
        
        first_elem = subtags.first[0]
        tags = t.fetch_all_by_tag(first_elem)
        
        tags.each do |subtag|
          if subtag.content = subtags[first_elem]  
            puts "Fixing #{t.to_marc}"
            t.add_at(MarcNode.new(Source, "a", "[missing]", nil), 0)
            t.sort_alphabetically
            puts "\t#{t}"
          end
        end
      end
      
      # we have valid marc
      # import it!
      import_marc = MarcSource.new(new_marc.to_marc)
      import_marc.load_source(false)
      import_marc.import
      
      source.marc = import_marc
      source.save!
      
    end
    
  end
  
end