count = 0

mc = MarcConfigCache.get_configuration("holding")

CSV::foreach("i-bc_holdings.csv").each do |r|
  s = Source.find(r[0])

  hold = s.holdings.where(lib_siglum: "I-Bc")

  if hold.size > 1 && hold.none? { |h| h.shelf_mark.strip == r[1].strip }
    puts "#{s.id}, #{r[1]}"
  end

  puts "No I-Bc holdings for #{s.id}" if hold.empty?

  hold.each do |h|

    # Make sure we have the correct one
    # if there is only one, it IS the correct one
    next if h.shelf_mark.strip != r[1].strip && hold.size > 1

    parts = h.marc.first_occurance("852", "q")
    count += 1 if parts&.content&.strip != r[3]&.strip

    the852 = h.marc.by_tags("852").first # if there is more than one we have other problems

    # Fix the material held
    parts.destroy_yourself if parts
    the852.add_at(MarcNode.new("holding", "q", r[3], nil), 0 ) if r[3]
    
    # Fix the shelfmark
    shmark = h.marc.first_occurance("852", "c")
    shmark.destroy_yourself if shmark
    the852.add_at(MarcNode.new("holding", "c", r[1], nil), 0 ) if r[1]
    
    the852.sort_alphabetically

    # Kill all the old 856
    h.marc.by_tags("856").each do |t|
      st = t.fetch_first_by_tag("u")
      #puts st.content if st.content.downcase != "[Bibliographic record]".downcase && st.content.downcase != "[Digital copy]".downcase
      #puts "#{h.id} #{st.content}" if !st.content.include?("bibliotecamusica.it")
      if st&.content&.include?("bibliotecamusica.it") || st&.content&.include?("id.sbn.it")
        t.destroy_yourself # ciaone
      end
    end

    # Add back the correct ones
    bib_link = r[2]
    digi_link = r[5]

    if digi_link
      a856 = MarcNode.new("holding", "856", "", mc.get_default_indicator("856"))

      a856.add_at(MarcNode.new("holding", "u", digi_link, nil), 0 )
      a856.add_at(MarcNode.new("holding", "x", "Digitized", nil), 0 )

      if r[6] && r[6].include?("extract")
        a856.add_at(MarcNode.new("holding", "z", "Digitized source, extract", nil), 0 )
      else
        a856.add_at(MarcNode.new("holding", "z", "Digitized source", nil), 0 )
      end
      a856.sort_alphabetically
      h.marc.root.add_at(a856, h.marc.get_insert_position("856") )
    end

    if bib_link
      a856 = MarcNode.new("holding", "856", "", mc.get_default_indicator("856"))

      a856.add_at(MarcNode.new("holding", "u", bib_link, nil), 0 )
      a856.add_at(MarcNode.new("holding", "x", "Other", nil), 0 )
      a856.add_at(MarcNode.new("holding", "z", "Original catalog entry", nil), 0 )
      a856.sort_alphabetically
      h.marc.root.add_at(a856, h.marc.get_insert_position("856") )
    else
      puts "#{s.id} #{h.id} #{r[1]} has no catalog entry"
    end

    if r[4]
      a500 = MarcNode.new("holding", "500", "", mc.get_default_indicator("500"))
      a500.add_at(MarcNode.new("holding", "a", r[4], nil), 0 )
      a500.sort_alphabetically
      h.marc.root.add_at(a500, h.marc.get_insert_position("500") )
    end

    PaperTrail.request.whodunnit = 'Rodolfo Zitellini'
    s.paper_trail_event = "Fix I-Bc holdings"

    h.save

  end
end

#puts count