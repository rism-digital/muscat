def decmpize(model)
  puts "De-cmpinzing #{model.to_s}"
  count =  model.where("marc_source like '%$4cmp%'").count
  pb = ProgressBar.new(count)

  model.where("marc_source like '%$4cmp%'").each do |s|
      save = false

      s.marc.each_by_tag("700") do |t|
          tgs = t.fetch_first_by_tag("4")
          tgs.content = "att" if tgs&.content == "cmp"
          save = true if tgs&.content == "att"
        end

      s.paper_trail_event = "Change 700 $4 cmp to att"
      s.save if save
      puts "Skip #{s.id}" if !save

      pb.increment!
  end
end

[Source, Holding, Institution, InventoryItem, Publication, Work, WorkNode].each {|m| decmpize(m)}