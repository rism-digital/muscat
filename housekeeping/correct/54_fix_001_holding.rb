all = []
pb = ProgressBar.new(Holding.all.count)

Holding.find_in_batches do |batch|

  batch.each do |s|
		pb.increment!

    if s.marc.by_tags("001").count == 0
      #puts s.id

      s.marc.root.add_at(MarcNode.new("holding", "001", s.id, nil), 0)
      s.suppress_update_77x
      s.suppress_recreate
      PaperTrail.request(enabled: false) do
        s.save
        
      end

    end

    #s.marc.each_by_tag("730") do |t|s
    #  puts s.id if t.fetch_all_by_tag("0").empty?
    #end

  end
end

#puts all.sort.uniq