all = []
#pb = ProgressBar.new(Source.all.count)
Source.find_in_batches do |batch|

  batch.each do |s|
		
    s.marc.load_source false

    s.marc.each_by_tag("700") do |t|
      tgs = t.fetch_all_by_tag("4")
      puts "700\t#{s.id}\t#{tgs.count}\t#{tgs}" if tgs.count > 1
    end

    s.marc.each_by_tag("710") do |t|
      tgs = t.fetch_all_by_tag("4")
      puts "710\t#{s.id}\t#{tgs.count}\t#{tgs}" if tgs.count > 1
    end

    #pb.increment!

  end

end

#puts all.sort.uniq