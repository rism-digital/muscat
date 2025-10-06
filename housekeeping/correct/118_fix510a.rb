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

Source.where("marc_source LIKE '%=510%'").find_in_batches do |batch|

    batch.each do |s|
        marc1 = s.marc_source
        s.marc.load_source true
        save = false

        s.marc["510"].each do |t|
            a = t["a"].first.content

            if a.include?("RISM")
                t["a"].first.content = a.gsub("RISM", "").strip
                save = true
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