def tag2str
end

headers = %w(
    001
    005
    240a
    245a
    260a
    260b
    260c
    510a
    510c
    650a
    852a
    588a
)

CSV.open("referred_sources.csv", "w") do |csv|
    csv << headers

    Source.joins(:referring_sources).distinct.each do |s|
        line = []

        line << s.id.to_s
        line << s.marc.first_occurance("005").content rescue line << ""

        line << s.marc.all_values_for_tags_with_subtag("240","a").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("245","a").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("260","a").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("260","b").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("260","c").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("510","a").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("510","c").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("650","a").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("852","a").join("; ")
        line << s.marc.all_values_for_tags_with_subtag("588","a").join("; ")

        #ap line
        csv << line

    end
end