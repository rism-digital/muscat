all = []
Source.find_in_batches do |batch|

  batch.each do |s|
		
    s.marc.each_by_tag("593") do |t|
      t.fetch_all_by_tag("a").each do |tn|

        next if !(tn && tn.content)
        all << tn.content

      end

    end
  end
end

puts all.sort.uniq