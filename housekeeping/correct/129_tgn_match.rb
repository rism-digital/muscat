def delete_024_tgn(marc)
  marc["024"].each do |t|
    if t["2"]&.first&.content == "TGN"
      t.destroy_yourself
    end
  end
end

#Place.find_each {|p| p.scaffold_marc; p.save if p.changed?}

name = ARGV[0]

CSV::foreach(name) do |line|
  tgn = line[0]&.gsub("tgn/", "")
  muscat = line[1]

  next if !muscat
  next if muscat.empty?

  next if !tgn
  next if tgn.empty?

  begin
    p = Place.find(muscat)
  rescue ActiveRecord::RecordNotFound
    puts "-> #{muscat} was deleted".red
    next
  end

    delete_024_tgn(p.marc)

    #p.marc.add_tag_with_subfields("024", a: tgn, "2": "TGN")

    begin
      TgnClientJson.new.fetch_marc_place(tgn, p.marc)
      puts "Pulled #{tgn} for #{p.id}"
    rescue
      puts "Could not pull #{tgn}"
      next
    end

  PaperTrail.request(enabled: false) do
    p.save
  end
end

# see 138_deduplicate places