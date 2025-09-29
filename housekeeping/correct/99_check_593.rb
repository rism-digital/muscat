all = []

grp_tags = ['260', '300', '590', '340', '028', '592', '700', '710', '500', '563', '856']

#pb = ProgressBar.new(Source.all.count)
Source.find_in_batches do |batch|

  batch.each do |s|

    s.marc.load_source false

    max_eight = 0

    grp_tags.each do |tgs|
      s.marc.each_by_tag(tgs) do |t|
        tt = t.fetch_all_by_tag("8")
        tt.each do |the_right|
          val = the_right&.content&.to_i
          max_eight = val if val > max_eight
        end
      end
    end

    #puts "#{s.id} #{max_eight}" if max_eight > 1

    the_eights = []
  
    s.marc.each_by_tag("593") do |t|
      tt = t.fetch_first_by_tag("8")
      the_eights << tt&.content&.to_i
    end

    st8 = the_eights.sort.uniq
    missing_numbers = (1..max_eight).to_a - st8

    puts "#{s.id}\t#{missing_numbers}" if missing_numbers.count > 0

    #pb.increment!

  end
end

#puts all.sort.uniq