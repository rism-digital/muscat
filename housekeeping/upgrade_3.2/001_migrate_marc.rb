require 'progress_bar'

# these fields come from marc conf
# alternatively we can search for $3 in all fields and signal
# unconfigured ones?
fields3 = ["260", "300", "340", "351", "590", "592", "593"]

# Do not save old versions
Source.paper_trail_off!

check_by_hand = []
unloadable_marc = []
uncorrelated_028 = []

pb = ProgressBar.new(Source.all.count)

Source.all.each do |s|
  
  pb.increment!
  
  begin
    marc = s.marc
    x = marc.to_marc
  rescue => e
    #puts e.exception
    unloadable_marc << s.id
    next
  end
  
  modified = false
  fields_mod = []
  fields_add = []
  index_028 = []
  
  fields3.each do |field|
  
    marc.each_by_tag(field) do |t|
    
      a = t.fetch_all_by_tag("3")

      if a.count > 0 # There is a $3, meaning more than one field
        subtag_changed = false

        a.each do |subtag|
          next if !subtag && !subtag.content
          
          # Translate "Material 1", "Material 2", etc into
          # only a number for $8
          material_no = subtag.content.split(" ")[1]
        
          t.add_at(MarcNode.new(Source, "8", sprintf("%02d", material_no), nil), 0)
          t.destroy_child(subtag)
          subtag_changed = true
        end
    
        if subtag_changed
          t.sort_alphabetically
      
          modified = true
          fields_mod << field
        end

      else # No $3 field, it is only one
        # Add $8 = 1 in this case
        t.add_at(MarcNode.new(Source, "8", "01", nil), 0)

        modified = true
        t.sort_alphabetically
      
        fields_add << field
      end  # if a
      
      # Additional step since we are looping anyways
      # See if there is a 593 Print (or more than one)
      # and save the $8 number and add it to the
      # (eventual) 028
      if field == "593"
        type = t.fetch_first_by_tag("a")
        if type && type.content && type.content == "Print"
          index_028 << t.fetch_first_by_tag("8").content
        end
      end
      
    end # each_by_tag
    
  end
  
  # Make the 028 tag have a $8 to the index
  # of the relative print material
  tags_028 = s.marc.by_tags("028")

  if index_028.count == 0 # No print reference found
    uncorrelated_028 << "#{s.id} has 028 but no 593 $a Print"
  elsif index_028.count == 1 # One print reference, set it to the 028s
    tags_028.each do |t|
      # Note the hardcoded [0] in index_028
      # Valid records have one oe more 028
      # but only ONE 593, if there ae more
      # set an error
      t.add_at(MarcNode.new(Source, "8", index_028[0], nil), 0)
      t.sort_alphabetically
    end
    modified = true
  else # More then one print reference!
    #puts "#{s.id} has 028 bur more than one 593 print"
    uncorrelated_028 << "#{s.id} has 028 bur more than one 593 print"
  end

  
  if modified
    # This case should never happen
    # There should be always one or the other
    # need to check by hand
    if fields_mod.count > 0 && fields_add.count > 0
      #puts "#{s.id} Has elements with material and without, skip"
      check_by_hand << s.id
    else
      #puts "Saving #{s.id}, fields: #{fields_mod.to_s}, added $8: #{fields_add.to_s}"
    	s.suppress_update_77x
    	s.suppress_update_count
    	s.suppress_reindex
      s.save!
   end
   
  end
  
end

puts "==============================="
puts "These elements need to be ckecked by hand:"
puts check_by_hand.to_s
puts "==============================="
puts "These elements could not load MARC:"
puts unloadable_marc.to_s
puts "==============================="
puts "These elements coould not correlate 028"
puts uncorrelated_028.to_s