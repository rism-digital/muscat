# grep "ORIG\|NEW" un000-output.txt | awk '{print $3}' | sort | uniq

def diffize(id, marc1, marc2)
  
    lines1 = marc1.split("\n")
    lines2 = marc2.split("\n")

    diffs = Diff::LCS.sdiff(lines1, lines2)

    diffs.each do |diff|
    case diff.action
#    when '='
    when '!'
        #puts "Line #{diff.old_position + 1} changed:"
        puts "#{id} ORIG #{diff.old_element}"
        puts "#{id} NEW  #{diff.new_element}"
    when '-'
        # Line was removed
        puts "#{id} REMOVED #{diff.old_position + 1}: #{diff.old_element}"
    when '+'
        # Line was added
        puts "#{id} ADDED   #{diff.new_position + 1}: #{diff.new_element}"
    end
    end

end

Source.find_in_batches do |batch|

    batch.each do |s|
        marc1 = s.marc_source
        s.marc.load_source true
        save = false

        s.marc.each_by_tag("001") do |t|
            if t.content.start_with? "0"
                puts "#{s.id} 001 #{t.content}"
                t.content = t.content.to_i.to_s
                save = true
            end
        end

        s.marc.each_by_tag("773") do |t|
            tgs = t.fetch_all_by_tag("w")
            tgs.each do |tt|
                next if tt.raw_content.is_a? Integer
                if tt.raw_content.start_with? "0"
                    puts "#{s.id} 773 #{tt.raw_content}"
                    tt.content = tt.raw_content.to_i.to_s
                    save = true
                end
            end
        end

        s.marc.each_by_tag("774") do |t|
            tgs = t.fetch_all_by_tag("w")
            tgs.each do |tt|
                next if tt.raw_content.is_a? Integer
                if tt.raw_content.start_with? "0"
                    puts "#{s.id} 774 #{tt.raw_content}"
                    tt.content = tt.raw_content.to_i.to_s
                    save = true
                end
            end
        end

        s.marc.each_by_tag("775") do |t|
            tgs = t.fetch_all_by_tag("w")
            tgs.each do |tt|
                next if tt.raw_content.is_a? Integer
                if tt.raw_content.start_with? "0"
                    puts "#{s.id} 775 #{tt.raw_content}"
                    tt.content = tt.raw_content.to_i.to_s
                    save = true
                end
            end
        end

        s.marc.each_by_tag("787") do |t|
            tgs = t.fetch_all_by_tag("w")
            tgs.each do |tt|
                next if tt.raw_content.is_a? Integer
                if tt.raw_content.start_with? "0"
                    puts "#{s.id} 787 #{tt.raw_content}"
                    tt.content = tt.raw_content.to_i.to_s
                    save = true
                end
            end
        end

        if save
            puts "#{s.marc.get_id} SAVING"

            PaperTrail.request(enabled: false) do
                s.suppress_reindex
                s.suppress_recreate
                s.suppress_update_count
                s.suppress_update_77x
                s.save
                marc2 = s.marc_source
                diffize(s.id, marc1, marc2)
                puts "#{s.marc.get_id} DONE"
            end

        end
    end


end