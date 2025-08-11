def normalize(s)
  #s.sub(/\A(\d{4})[|\u00A6]/, '\1/')   # first sep -> slash
  s.sub(/\A(\d{4}|\[.*?\])[|\u00A6]/, '\1/')
  .gsub(/[|\u00A6]/, '')              # remove the rest
end


Source.where("marc_source LIKE '%=510%'").each do |s|
  
  save = false
  s.marc.load_source

  s.marc["510"].each do |t|
    a = t["a"].first.content

    if a == "B/I" || a == "RISM B/I"
      c = t['c'].first.content rescue ""
      if !c.empty? or a == "RISM B/I"
        t["a"].first.content = "B/I"
        t["c"].first.content = normalize(c) if !c.empty?
        save = true
      end
    end

  end

  if save
    s.paper_trail_event = "Normalise 510$c"
    s.save
    puts s.id
  end

end
