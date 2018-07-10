require 'progress_bar'
pb = ProgressBar.new(Source.all.count)

newFile = File::open('grfia.txt','w')

Source.find_in_batches.each do |group|
  group.each do |source|
    source.marc.load_source false
    source.marc.each_by_tag("031") do |t|
    
      vals = {}
      [:a, :b, :c].each do |st|
        v = t.fetch_first_by_tag(st)
        vals[st] = v && v.content ? v.content : "0"
      end
      
      pae_nr = "#{vals[:a]}.#{vals[:b]}.#{vals[:c]}"
      
      key = t.fetch_first_by_tag("n")
      time = t.fetch_first_by_tag("o")
      clef = t.fetch_first_by_tag("g")
      pae = t.fetch_first_by_tag("p")
      
      ## Nothing to do here
      next if !pae || !pae.content
      
      key = key && key.content ? "$#{key.content}" : ""
      time = time && time.content ? "@#{time.content}" : ""
      clef = clef && clef.content ? "%#{clef.content}" : ""
      
      full_pae = "#{clef}#{time}#{key}#{pae}"
      
      full_string = "#{source.id}\t#{pae_nr}\t#{source.composer}\t#{source.title}\t#{full_pae}\n"
      newFile <<  full_string
    end
    pb.increment!
  end
end

newFile.close()