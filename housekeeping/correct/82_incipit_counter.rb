all = 0
#pb = ProgressBar.new(Source.all.count)
Source.where("lib_siglum LIKE 'CH%'").where("created_at >= '2021-01-01 00:00:00'").where("created_at < '2024-01-01 00:00:00'").each do |s|
		
    s.marc.load_source false

    s.marc.each_by_tag("031") do |t|
      tgs = t.fetch_all_by_tag("p")
      all += tgs.count
    end

  end


puts all