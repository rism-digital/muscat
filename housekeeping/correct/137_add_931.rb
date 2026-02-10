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

SourceWorkRelation.find_each do |wr|
  
  s = wr.source
  marc1 = s.marc_source

  s.marc.add_tag_with_subfields("931", "0": wr.work_id, "4": wr.relator_code)
  s.marc.import

  s.save
  marc2 = s.marc_source
  diffize(s.id, marc1, marc2)
  puts "#{s.marc.get_id} DONE"

end