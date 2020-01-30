CSV::foreach("housekeeping/upgrade_ch/composite_volumes.tsv", col_sep: "\t") do |r|
    next if r[0] && r[0].include?("man")

    puts r[0]
end