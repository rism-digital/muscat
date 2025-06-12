Work.all.each do |w|
  save = false
  date = w.marc.by_tags("046")

  date.each do |dtag|
    
    next if !dtag.fetch_first_by_tag("l")
    next if !dtag.fetch_first_by_tag("k")

    start = dtag.fetch_first_by_tag("k")
    later = dtag.fetch_first_by_tag("l")

    # Who uses NON BREAKING SPACES IN THE DATA OH MY!!!
    start.content = "#{start.content.strip}/#{later.content.strip}".strip.gsub(" ", "")
    later.destroy_yourself
    save = true
  end

  if save
    p w.id
    w.paper_trail_event = "Consolidate 046 $l and $k"
    w.save
  end

end