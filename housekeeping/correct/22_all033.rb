def join_values(tag, subtag, marc)
  values = []
  marc.by_tags(tag).each do |t|
    t.each_by_tag(subtag) do |st|
      next if !st || !st.content
      values << st.content.gsub("\"", "\'")
    end
  end
  values
end

#puts "id\tcatalog\txml\tedit\tdate\tsiglum\tuser\t518$a\t541$d\t260$c\t500$a\t245$a\t246$a"
puts ["id", "groups", "033a", "518a", "541a", "260a", "500a"].join(",")
Source.where(source_id: nil).find_in_batches do |batch|
  batch.each do |s|

    #next if s.source_id != nil

    s.marc.load_source false
    m = s.marc
    next if m.by_tags("033").count == 0

    groups = m.all_values_for_tags_with_subtag("300", 8).count

    a = []
    a << "\"#{s.id.to_s}\""
    a << "\"#{groups.to_s}\""
    a << "\"#{join_values("033", "a", m).join("\n")}\""
    a << "\"#{join_values("518", "a", m).join("\n")}\""
    a << "\"#{join_values("541", "d", m).join("\n")}\""
    a << "\"#{join_values("260", "c", m).join("\n")}\""
    a << "\"#{join_values("500", "a", m).join("\n")}\""
    #a << "\"#{join_values("245", "a", m).join("\n")}\""
    #a << "\"#{join_values("246", "a", m).join("\n")}\""
    
    puts a.join(",")
    
  end
end