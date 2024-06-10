count = 0
Person.find_in_batches do |batch|

    batch.each do |s|
        mod = false
        s.marc.load_source false

        s.marc.each_by_tag("856") do |t|
            t.fetch_all_by_tag("y").each do |offending|
                puts "#{s.id} #{offending.to_s}"
                t.add_at(MarcNode.new("person", "z", offending.content, nil), 0 )
                offending.destroy_yourself
                t.sort_alphabetically
                mod = true
            end
        end

        s.save if mod
        count +=1 if mod
    end
  
end

puts count