all = []
Work.all.each do |w|

    w.marc.each_by_tag("930") {|t2| t2.destroy_yourself}

    w.save
end

