ids = {
:"40206338" =>	30002240,
:"40200390" =>	1874,
:"40200563" =>	88790,
:"40212026" =>	249507,
:"40206277" =>	30020903,
:"40205915" =>	30001209,
:"40219549" =>	30002070,
:"41021332" =>	30086797,
:"41021336" =>	30006703,
:"40209469" =>	30004867,
:"40221289" =>	90691,
:"41019658" =>	40200689,
:"41023355" =>	132082,
:"40204575" =>	30001251,
:"41021315" => 30004985,
:"41021333" => 30004985,
:"41022149" => 30004985,
:"41022430" => 30004985,
:"41022958" => 30004985,
:"41023389" => 30004985,
:"41019641" => 40200416
}

Work.all.each do |w|
    mod = false
    w.marc.load_source false

    w.marc.each_by_tag("100") do |t|
        t.fetch_all_by_tag("0").each do |tn|
            next if !(tn && tn.content)
            if ids.include?(tn.content.to_sym)
                tn.content = ids[tn.content.to_sym]
                mod = true
            end
        end
    end

    w.marc.each_by_tag("400") do |t|
        t.fetch_all_by_tag("0").each do |tn|
            next if !(tn && tn.content)
            if ids.include?(tn.content.to_sym)
                tn.content = ids[tn.content.to_sym]
                puts tn.content
                mod = true
            end
        end
    end


    w.marc.each_by_tag("700") do |t|
        t.fetch_all_by_tag("0").each do |tn|
            next if !(tn && tn.content)
            if ids.include?(tn.content.to_sym)
                tn.content = ids[tn.content.to_sym]
                mod = true
            end
        end
    end

    if mod
        w.marc_source = w.marc.to_marc
        w.save
    end

end