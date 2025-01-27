CSV::foreach("housekeeping/scrapbook/the_last_of_the_polypens.tsv", col_sep: "\t", headers: true, quote_char: "\x00") do |r|
    next if !r["id"]

    s = Source.find(r["id"])

    s.marc_source.gsub!(r["word"], r["sub"])
    s.paper_trail_event = "Fix protypen 2 #{r["word"]} with #{r["sub"]}"
    s.save
    puts s.id
end