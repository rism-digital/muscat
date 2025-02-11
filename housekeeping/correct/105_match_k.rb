regex = /(?i)(k)[[:punct:]\s]*([0-9]+[a-z]?)/

col = Source.find(850776190)

col.child_sources.each do |cs|

    cs.marc.each_by_tag("730") do |t|
        t.each_by_tag("a") do |st|
            next if !st
            next if !st.content

            if match = st.content.match(regex)
                k_part    = match[1]  # "K"
                numberish = match[2]  # "123"
                puts "#{cs.id}\t#{st.content}\t#{k_part}\t#{numberish}"
            end
        end

    end
end