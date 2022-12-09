all = []
#Source.where("record_type = 1").each do |c|
File.readlines("all_collections.txt").each do |l|
    c = Source.find(l)

    found = 0

    next if c.child_sources.count == 0

    c.child_sources.each do |s|
        s.marc.load_source false
        #next if s.marc.by_tags("593").count == 1
        #next if s.marc.by_tags("773").count > 0

        skip = false
        s.marc.each_by_tag("340") do |t|
            t.fetch_all_by_tag("d").each do |tn|
            next if !(tn && tn.content)
            if tn.content == "Autography" ||
                tn.content =="Computer printout" ||
                tn.content =="Offset printing" ||
                tn.content =="Photoreproductive process" ||
                tn.content =="Transparency" ||
                tn.content =="Typescript" ||
                tn.content == "Reproduction"
                skip = true
            end
            end
        end

        next if skip

        s.marc.each_by_tag("593") do |t|
            
            t.fetch_all_by_tag("a").each do |tn|

            next if !(tn && tn.content)
            next if !tn.content.starts_with?("Print")
            all << s.id
            #puts "#{s.id}"
            found +=1

            end

        end
    end

    puts c.id if found != c.child_sources.count

end


#puts all.sort.uniq
#puts all.sort.uniq.count