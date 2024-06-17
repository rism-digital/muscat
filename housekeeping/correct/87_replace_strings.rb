all = []
#pb = ProgressBar.new(Source.all.count)
Source.find_by_sql("select * from sources where marc_source like \"%JWpostImport:%\"") do |s|

  #s.marc.load_source false

  s.marc.each_by_tag("599") do |t|
    tgs = t.fetch_all_by_tag("a")
    tgs.each do |t|
      if t.content.include?("JWpostImport:")
        t.content = t.content.gsub("JWpostImport: ", "").gsub("  ", " ")
        puts "#{s.id}\t#{t.content}"
      end
    end
  end
  
  #pb.increment!
  #s.save
end

#puts all.sort.uniq