def decmpize(model)
  puts "De-cmpinzing #{model.to_s}"
  count =  model.where("marc_source like '%$4cmp%'").count
  pb = ProgressBar.new(count)

  tag = "700"
  tag = "500" if model == Work

  model.where("marc_source like '%$4cmp%'").each do |s|
      save = false

      s.marc.each_by_tag(tag) do |t|
          t.fetch_all_by_tag("4").each do |tgs|
            tgs.content = "att" if tgs&.content == "cmp"
            save = true if tgs&.content == "att"
          end
        end

      #s.paper_trail_event = "Change 700 $4 cmp to att"
      PaperTrail.request(enabled: false) do
        s.suppress_reindex if s.respond_to? :suppress_reindex
        s.suppress_scaffold_marc if s.respond_to? :suppress_scaffold_marc
        s.suppress_recreate if s.respond_to? :suppress_recreate
        s.suppress_update_count if s.respond_to? :suppress_update_count
        s.suppress_update_77x if s.respond_to? :suppress_update_77x
        s.suppress_update_workgroups if s.respond_to? :suppress_update_workgroups
        s.save if save
      end
      puts "Skip #{s.id}" if !save

      pb.increment!
  end
end

[Source, Holding, Institution, InventoryItem, Publication, Work].each {|m| decmpize(m)}