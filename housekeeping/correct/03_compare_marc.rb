def compare_records(buffer, line, csv_file)
  
  marc_a = MarcSource.new(buffer)
  # load the source but without resolving externals
  marc_a.load_source(false)
  id =  marc_a.first_occurance("001").content
    
  s = Source.find(id)
  marc_b = MarcSource.new(s.marc_source)
  marc_b.load_source(false)
  
  all_tags_a = marc_a.all_tags.map {|t| t.tag}.uniq
  all_tags_b = marc_b.all_tags.map {|t| t.tag}.uniq
  
  missing_b = all_tags_a - all_tags_b
  missing_a = all_tags_b - all_tags_a
  
  if !missing_a.empty?
    csv_file.puts "#{id}\tMARC A TAG-MISSING\ttags: #{missing_a}"
  end
  
  if !missing_b.empty?
    csv_file.puts "#{id}\tMARC B TAG-MISSING\ttags: #{missing_b}"
  end
  
  common_tags = all_tags_a + all_tags_b - missing_a - missing_b

  common_tags.each do |tag|
    marcnodes_a = marc_a.by_tags(tag)
    marcnodes_b = marc_b.by_tags(tag)
    
    count_a = marcnodes_a.map {|t| t.tag}.count
    count_b = marcnodes_b.map {|t| t.tag}.count
    
    if count_a != count_b
      csv_file.puts "#{id}\tDIFFERENT COUNT\ttag #{tag}, A: #{count_a}, B: #{count_b}, skipping"
      next
    end
    
    # Hope the marcnodes array are ordered in the same way
    for pos in 0..count_a - 1 do
      node_a = marcnodes_a[pos]
      node_b = marcnodes_b[pos]
      
      subtags_a = []
      node_a.each {|n| subtags_a << n.tag}
      subtags_b = []
      node_b.each {|n| subtags_b << n.tag}
      
      subtags_a.uniq!
      subtags_b.uniq!
      
      missing_subtags_b = subtags_a - subtags_b
      missing_subtags_a = subtags_b - subtags_a
      common_subtags = subtags_a + subtags_b - missing_subtags_a - missing_subtags_b
      
      if !missing_subtags_a.empty?
        csv_file.puts "#{id}\tMARC A SUBTAG-MISSING\ttag: #{tag}[#{pos}], subtags: #{missing_subtags_a}"
      end
  
      if !missing_subtags_b.empty?
        csv_file.puts "#{id}\tMARC B SUBTAG-MISSING\ttag: #{tag}[#{pos}], subtags: #{missing_subtags_b}"
      end
      
      # Get tge various $ tags
      common_subtags.each do |subtag|
        
        subtags_in_a = node_a.fetch_all_by_tag(subtag)
        subtags_in_b = node_b.fetch_all_by_tag(subtag)
        
        if subtags_in_a.count != subtags_in_b.count
          csv_file.puts "#{id}\tDIFFERENT SUBTAG COUNT\ttag #{tag}[#{[pos]}], subtag: #{subtag} A: #{subtags_in_a.count}, B: #{subtags_in_b.count}, skipping"
        end
        
        for sub_pos in 0..subtags_in_a.count - 1 do
          if subtags_in_a[sub_pos].content != subtags_in_b[sub_pos].content
           csv_file.puts "#{id}\tCONTENT DIFFERENT\ttag #{tag}[#{pos}], subtag: #{subtag}[#{sub_pos}] A: #{subtags_in_a[sub_pos].content}, B: #{subtags_in_b[sub_pos].content}"
          end
        end
        
      end
      
    end
  end
    
end

pb = ProgressBar.new(Source.all.count)
buffer = ""
line_number = 0
File.open("marc_dump.txt", "r") do |f|
  File.open("compare_output.csv", "w") do |out|
  
    f.each_line do |line|
      line_number += 1
      if line =~ /^\s+$/
        # ignore
      elsif line =~ /^=000/
        if buffer.length > 0
          compare_records(buffer, line_number, out)
          pb.increment!
        end
        buffer = line
      else
        buffer += line
      end
    end
  
    compare_records(buffer, line_number, out)
    pb.increment!
  end
end

