
map = {
"book" => "Monograph",
"periodical" => "Periodical",
"series" => "Series",
"individual item" => "Volume in a series",
"item" => "Article/chapter",
}

all = 0
oldall = 0
#pb = ProgressBar.new(Source.all.count)
Publication.all.each do |s|

  #s.marc.load_source false

  s.marc.each_by_tag("240") do |t|
    tgs = t.fetch_all_by_tag("h")
    tgs.each do |t|

        map.each do |k, v|
            if t.content.include?(k)
                t.content = v
                ap t
                all +=1
            end 
        end

    end
  end

=begin
  s.marc.by_tags("100").each do |t|
    tt = t.fetch_first_by_tag("0")
    puts t if !tt
    all += 1 if !tt

    t.destroy_yourself if !tt
  end

  s.marc.by_tags("760").each do |t|
    tt = t.fetch_first_by_tag("0")
    puts t if !tt
    all += 1 if !tt

    t.destroy_yourself if !tt
  end
=end

  #pb.increment!
  s.save if oldall != all
  oldall = all
end

#puts all.sort.uniq
puts all