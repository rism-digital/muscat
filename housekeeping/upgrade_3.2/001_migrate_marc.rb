# these fields come from marc conf
# alternatively we can search for $3 in all fields and signal
# unconfigured ones?
fields3 = ["260", "300", "340", "351", "590", "592", "593"]

Source.all.each do |s|

  begin
    marc = s.marc
    x = marc.to_marc
  rescue => e
    puts e.exception
    next
  end

  modified = false
  fields_mod = []

  fields3.each do |field|

    marc.each_by_tag(field) do |t|

      a = t.fetch_all_by_tag("3")
      next if !a

      subtag_changed = false

      a.each do |subtag|
        next if !subtag && !subtag.content

        t.add_at(MarcNode.new(Source, "8", subtag.content, nil), 0)
        t.destroy_child(subtag)
        subtag_changed = true
      end

      if subtag_changed
        t.sort_alphabetically

        modified = true
        fields_mod << field
      end
    end
  end

  if modified
    puts "Saving #{s.id}, fields #{fields_mod.to_s}"
    s.save!
  end

end
