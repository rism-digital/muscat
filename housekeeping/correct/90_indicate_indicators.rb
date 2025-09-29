pb = ProgressBar.new(Source.all.count)
mega = {}
Source.find_in_batches do |batch|

    batch.each do |s|

      s.marc.load_source false

        s.marc.all_tags.each do |tag|
            tag.each do |st|
              mega[st.indicator] = 0 if !mega.keys.include? st.indicator  && st.indicator
              mega[st.indicator] += 1 if st.indicator
            end
          end

        pb.increment!
    end
end
ap mega