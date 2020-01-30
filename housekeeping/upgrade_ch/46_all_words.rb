incorrect = YAML::load(File.read("housekeeping/upgrade_ch/subst_sanit.yml"))

pb = ProgressBar.new(Source.all.count)

newFile = File::open("more_words_upcase.txt",'w')


Source.all.each do |su|
  #items.each do |sid|
  source = Source.find(su.id)
  pb.increment!

  modified = false
  source.marc.load_source true
  source.marc.all_tags.each do |tag|

    tag.each do |subt|
      next if !subt.content
      

      subt.content.to_s.split(" ").each do |tok|
        
        #m = tok.match(/\b(ö\S*)\b/) # Starting with ö
        m = tok.match(/([A-Z]+ö[A-Z]+)/) #uppercase with ö
        if m
          if !incorrect.keys.include?(m[0])
            newFile << m[0] 
            newFile << "\n"
          end
        end
        
      end #split

        
      
    end
  end #all_tags

  source = nil
end

newFile.close