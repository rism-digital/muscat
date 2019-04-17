count = 0

origFile = File::open("orig_lines.txt",'w')
newFile = File::open("new_lines.txt",'w')


incorrect = YAML::load(File.read("housekeeping/upgrade_ch/all_words.yml"))
count = 0
#Source.all.each do |su|
Parallel.each(Source.all, in_processes: 10, progress: "Fixing encoding") do |su|
#items.each do |sid|
  source = su #Source.find(su.id)

  modified = false
  found_words = []
  source.marc.load_source true
  source.marc.all_tags.each do |tag|

    tag.each do |subt|
      next if !subt.content
      
      incorrect.each do |inc, more|
        found = false
        toks = []
        
        subt.content.to_s.split(" ").each do |tok|
          #puts tok.blue
          #if tok == inc
          #if tok.match(/\b(#{Regexp.quote(inc)})\b/)# == inc
					if tok.sub!(/\b(#{Regexp.quote(inc)})\b/, more[:correct])
						origFile << subt.content.strip if !found #just print it once
						origFile << "\n" if !found
            #tok = more[:correct]
            #tok.sub!(/\b(#{Regexp.quote(inc)})\b/, more[:correct])
            found = true
            count += 1 if !found
            found_words << tok #sve all the changed words
          end
          toks << tok
        end #split
        subt.content = toks.join(" ") if found
        #puts subt.content if found
				newFile << subt.content if found
				newFile << "\n" if found
        #puts source.id if found
        modified = true if found
        
      end #incorrect
      
    end
  end #all_tags
  
  #puts source.marc.to_s
  source.paper_trail_event = "Fix encoding: #{found_words.sort.uniq.join(" ")}"
  source.save if modified
  source = nil
end

origFile.close
newFile.close

puts count