require 'progress_bar'

# Delete all the records that reference a source_id that does not exist
orphans = Source.find_by_sql("select s2.id from sources as s right join sources as s2 on s.id = s2.source_id where s.id is null and s2.source_id is not null;")
orphans.each {|o| o.delete}

ActiveRecord::Base.connection.execute("UPDATE sources SET record_type = 2 WHERE record_type = 8 OR record_type = 6")
ActiveRecord::Base.connection.execute("DELETE FROM sources WHERE id = 225000014")


pb = ProgressBar.new(Source.all.count)

Source.all.each do |sa|
  
  s = Source.find(sa.id)
  
  marc = s.marc
  #marc.load_source(false)

  #Kill 772 $a
  marc.each_by_tag("772") do |t|
    t.fetch_all_by_tag("a").each {|st| st.destroy_yourself}
  end
  
  marc.each_by_tag("100") do |t|
    tj = t.fetch_first_by_tag("j")
    
    next if !(tj && tj.content)
    letter = tj.content
    
    if letter == "e"
      word = "Ascertained"
    elsif letter == "z"
      word = "Doubtful"
    elsif letter == "g"
      word = "Verified"
    elsif letter == "f"
      word = "Misattributed"
    elsif letter == "l"
      word = "Alleged"
    elsif letter == "m"
      word = "Conjectural"
    else
      word = "unknown"
      puts "Unknown $j value #{letter}"
    end
    
    tj.destroy_yourself #adios
    t.add_at(MarcNode.new("source", "j", word, nil), 0)
    t.sort_alphabetically
  end
  
  marc.each_by_tag("700") do |t|
    tj = t.fetch_first_by_tag("j")
    
    next if !(tj && tj.content)
    letter = tj.content
    
    if letter == "e"
      word = "Ascertained"
    elsif letter == "z"
      word = "Doubtful"
    elsif letter == "g"
      word = "Verified"
    elsif letter == "f"
      word = "Misattributed"
    elsif letter == "l"
      word = "Alleged"
    elsif letter == "m"
      word = "Conjectural"
    else
      word = "unknown"
      puts "Unknown $j value #{letter}"
    end
    
    tj.destroy_yourself #adios
    t.add_at(MarcNode.new("source", "j", word, nil), 0)
    t.sort_alphabetically
  end
  
	s.suppress_update_77x
	s.suppress_update_count
  s.suppress_reindex

  #puts new_marc
  
  #begin
    s.save
    #rescue => e
    #puts e.message
    #end
  
  pb.increment!
  
end