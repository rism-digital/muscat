Source.find_in_batches do |batch|

  batch.each do |s|
		
    s.marc.each_by_tag("700") do |t|
      tn = t.fetch_first_by_tag("a")

	      next if !(tn && tn.content)
				
      if tn.content == "Liebeskind, Josef"
        tt = t.fetch_first_by_tag("4")
				
        if tt && tt.content
          puts s.id if tt.content == "fmo"
        end
			end
      
    end
  end
end