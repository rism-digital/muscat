tag_count = {}
pb = ProgressBar.new(Source.count)

Source.find_in_batches do |batch|

    batch.each do |src|
        s = Source.find(src.id)
        pb.increment!

        s.marc.load_source false
        marc = s.marc

        marc.all_tags.each do |tag|
            
            if !tag_count.include?(tag.tag)
                tag_count[tag.tag] = {}
                tag_count[tag.tag][:count] = 0
                tag_count[tag.tag][:subtags] = {}
            end
            
            tag_count[tag.tag][:count] += 1

            tag.children.each do |subtag|
                if !tag_count[tag.tag][:subtags].include?(subtag.tag)
                    tag_count[tag.tag][:subtags][subtag.tag] = {}
                    tag_count[tag.tag][:subtags][subtag.tag][:count] = 0
                    tag_count[tag.tag][:subtags][subtag.tag][:first] = src.id
                end
                tag_count[tag.tag][:subtags][subtag.tag][:count] += 1
            end
        end
    end
end

puts tag_count.to_yaml