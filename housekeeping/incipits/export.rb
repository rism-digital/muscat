require 'progress_bar'
#pb = ProgressBar.new(Source.all.count)


#File.open("incipits.txt", "w") do |file|
count = 0
CSV.open("incipits.csv", "w", force_quotes: true) do |csv|
    Source.find_in_batches.each do |group|
        group.each do |source|
            source.marc.load_source false
            source.marc.each_by_tag("031") do |t|
                    
                subtags = [:a, :b, :c, :g, :n, :o, :p, :m]
                vals = {}
                
                subtags.each do |st|
                    v = t.fetch_first_by_tag(st)
                    vals[st] = v && v.content ? v.content : ""
                end
                
                next if vals[:p] == 'nil'

                #file.write("#{source.id}\t#{vals[:a]}\t#{vals[:b]}\t#{vals[:c]}\t#{vals[:g]}\t#{vals[:n]}\t#{vals[:o]}\t#{vals[:p]}\n")
                csv << [source.id, "https://muscat.rism.info/admin/sources/#{source.id}/edit", vals[:a], vals[:b], vals[:c], vals[:g], vals[:n], vals[:o], vals[:p], vals[:m] ]

                count += 1

                if count % 10000 == 0
                    puts "s #{source.id} c #{count}"
                end
            end

            #pb.increment!
        end
    end

end
