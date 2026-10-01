URL="https://muscat.rism.info/admin/sources/"
CSV::foreach("psmd.csv", headers: %i[mid link series number title author]) do |r|
  

  hits = Source.solr_search {fulltext(r[:number], fields: "510c"); with(:"510c", r[:number]); adjust_solr_params {|p| p["q.op"] = "AND"}}

  if hits.results.count == 1
    s = hits.results.first
    puts CSV.generate_line([r[:mid], s.id, r[:link], URL+s.id.to_s, r[:number], r[:title], s.std_title, r[:author], s.composer, s.marc.all_tags.count.to_s, s.child_sources.count.to_s])
  elsif hits.results.count == 0
    #puts [r[:mid], r[:link], r[:number], r[:title], r[:author]].join("\t") 
  elsif hits.results.count > 1
    cnt = 0
    hits.results.each do |s|

      new_t = []
      s.marc.by_tags("510").each do |t|
              c = t.fetch_first_by_tag("c").content.strip if t.fetch_first_by_tag("c")
              a = t.fetch_first_by_tag("a").content.strip if t.fetch_first_by_tag("a")
              new_t << c
      end
      cnt += 1
      #puts CSV.generate_line([cnt.to_s, r[:mid], s.id, r[:link], URL+s.id.to_s, r[:number], new_t.compact.join(" ").strip, r[:title], s.std_title, r[:author], s.composer, s.marc.all_tags.count.to_s, s.child_sources.count.to_s]) 
    end
  end

end