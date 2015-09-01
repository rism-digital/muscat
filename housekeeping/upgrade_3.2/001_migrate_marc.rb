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
  index_028 = -1
  
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
        
          t.add_at(MarcNode.new(Source, "8", material_no, nil), 0)
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
        t.add_at(MarcNode.new(Source, "8", 1, nil), 0)

        modified = true
        t.sort_alphabetically
      
        fields_add << field
      end  # if a
      
      # Additional step since we are looping anyways
      # See if there is a 593 Print (or more than one)
      # and save the $8 number and add it to the
      # (eventual) 028
      if field == "593" && index_028 == -1
        type = t.fetch_first_by_tag("a")
        if type && type.content && type.content == "Print"
          index_028 = t.fetch_first_by_tag("8").content
        end
      end
      
    end # each_by_tag
    
  end
  
  # Make the 028 tag have a $8 to the index
  # of the relative print material
  tag_028 = s.marc.by_tags("028")
  if tag_028.count > 1
    # More 028s, what to do?
    uncorrelated_028 << "#{s.id} more than 1 028"
  elsif tag_028.count == 1
    if index_028 == -1 # No print reference found
      uncorrelated_028 << "#{s.id} has 028 but no 593 $a Print"
    else
      tag_028.first.add_at(MarcNode.new(Source, "8", index_028, nil), 0)
      tag_028.first.sort_alphabetically
      modified = true
    end
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
      #s.save!
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