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
nonprint_028 = []

pb = ProgressBar.new(Source.all.count)

Source.all.each do |sa|
  
  s = Source.find(sa.id)
  
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
  print_593 = []
  has_593_print = 0
  
  fields3.each do |field|
    marc.each_by_tag(field) do |t|
      a = t.fetch_all_by_tag("3")
      if a.count > 0
        fields_mod << field
      else
        fields_add << field
      end
    end
  end
  
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
          #fields_mod << field
        end

      else #
        
        if !fields_mod.empty?
          puts "No $3 #{field} - #{s.id}"
          next
        end
        
        # Add $8 = 1 in this case
        t.add_at(MarcNode.new(Source, "8", "01", nil), 0)

        modified = true
        t.sort_alphabetically
      
        #fields_add << field
      end  # if a
      
      # Additional step since we are looping anyways
      # See if there is a 593 Print (or more than one)
      # and save the $8 number and add it to the
      # (eventual) 028
      if field == "593"
        type = t.fetch_first_by_tag("a")
        # always correlate 593
        if type && type.content #&& type.content == "Print"
          print_593 << [t.fetch_first_by_tag("8").content, type.content]
          has_593_print += 1 if type.content == "Print" #shorthand
        end
      end
      
    end # each_by_tag
    
  end
  
  # Make the 028 tag have a $8 to the index
  # of the relative print material
  tags_028 = s.marc.by_tags("028")

  if print_593.count == 0 # No print reference found
    uncorrelated_028 << "#{s.id} has 028 but no 593 $a Print" if tags_028.count > 0
  elsif print_593.count == 1 # One print reference, set it to the 028s
    tags_028.each do |t|
      # Note the hardcoded [0] in print_593
      # Valid records have one oe more 028
      # but only ONE 593, if there ae more
      # set an error
      t.add_at(MarcNode.new(Source, "8", print_593[0][0], nil), 0)
      t.sort_alphabetically
      if print_593[0][1] != "Print"
        puts "w: #{s.id} 539 is #{print_593[0][1]}"
        nonprint_028 << s.id
      end
    end
    modified = true
  else # More then one 593 reference!
    # Now if there is one and only one 'print' 593
    # we ignore the others and correlate to that
    # if not we cannot correlate any
    
    if has_593_print == 1
      
      # Get the print one
      index = -1
      print_593.each do |p|
        if p[1] == "Print"
          index = print_593.find_index(p)
        end
      end
      
      if index == -1
        puts "No print found but has_593_print == 1, the program is broken"
      end
      
      tags_028.each do |t|
        # This is copy and paste from above
        # sorry
        t.add_at(MarcNode.new(Source, "8", print_593[index][0], nil), 0)
        t.sort_alphabetically
        if print_593[index][1] != "Print"
          puts "#{s.id} 539 is #{print_593[1]} THIS SHOLD NOT HAPPEN"
        end
      end
    elsif has_593_print > 1
      puts "#{s.id} has 028 but more than one 593 Print" if tags_028.count > 0
      uncorrelated_028 << s.id if tags_028.count > 0
    else
      puts "#{s.id} has 028 but more than one 593 (and no Print)" if tags_028.count > 0
      uncorrelated_028 << s.id if tags_028.count > 0
    end
  end


  # Do some additional housekeeping
  # Kill 005 and 008
  marc.each_by_tag("008") do |t|
    t.destroy_yourself
    modified = true
  end
  marc.each_by_tag("005") do |t|
    t.destroy_yourself
    modified = true
  end

  # Make sure all 031 have $2pe
  marc.each_by_tag("031") do |incipit|
    tags = incipit.fetch_all_by_tag("2")
    if tags.count == 0
      incipit.add_at(MarcNode.new(Source, "2", "pe", nil), 0)
      incipit.sort_alphabetically
    end
  end

  # Lastly get into each tag and
  # 1) remove $_
  # 2) sort_alphabetically
  tgs = marc.all_tags
  tgs.each do |t|
    t.sort_alphabetically
    a = t.fetch_all_by_tag("_")
    next if a.count == 0
    a.each do |st|
      t.destroy_child(st)
    end
    modified = true
  end

  
  if modified
    # This case should never happen
    # There should be always one or the other
    # need to check by hand
    if fields_mod.count > 0 && fields_add.count > 0
      #puts "#{s.id} Has elements with material and without, skip"
      check_by_hand << s.id
    end
    
    #puts "Saving #{s.id}, fields: #{fields_mod.to_s}, added $8: #{fields_add.to_s}"
  	s.suppress_update_77x
  	s.suppress_update_count
  	s.suppress_reindex
    s.save!
  end
  
end

puts "==============================="
puts "These elements have marerial tags with and without $3:"
puts check_by_hand.to_s

srcs = Source.find(nonprint_028)
f = Folder.new(:name => "Manuscripts with 028 Plate Nr.", :folder_type => "Source")
f.save
f.add_items(srcs)

Sunspot.index f.folder_items
Sunspot.commit

srcs = Source.find(uncorrelated_028)
f = Folder.new(:name => "Sources with more than one 593", :folder_type => "Source")
f.save
f.add_items(srcs)

Sunspot.index f.folder_items
Sunspot.commit