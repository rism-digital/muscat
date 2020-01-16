pb = ProgressBar.new(Source.all.count)

newFile = File::open("as.txt",'w')

#items.each do |sid|
Source.all.each do |s|
  pb.increment!
  source = Source.find(s.id)

  source.marc.load_source false
  source.marc.all_tags.each do |tag|

    tag.each do |subt|
      next if !subt.content

      subt.content.to_s.split(" ").each do |tok|
        m = tok.match(/\b(\S*á\S*)\b/)
        if m
          newFile << m[0]
          newFile << "\n"
        end
      end
    end
    
  end
  
  source = nil
end

newFile.close