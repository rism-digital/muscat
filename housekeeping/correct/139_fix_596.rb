rows = CSV.parse(File.read("596-script.tsv"), col_sep: "\t", headers: %i[id link link2 olda oldb a b])

def fixyfixy(the_t, a, b)
  the_t["a"].each {|a| a.destroy_yourself}
  the_t["b"].each {|b| b.destroy_yourself}

  the_t.add_at(MarcNode.new("source", "a", a, nil), 0)
  the_t.add_at(MarcNode.new("source", "b", b, nil), 0)
  the_t.sort_alphabetically

end

rows.each do |r|

  s = Source.find(r[:id])
#puts s.id
  if s.marc["596"].count > 1
    the_t = nil

    s.marc["596"].each do |t|
      a = t["a"].first.content
      b = t["b"].first.content

      the_t = t if a == r[:olda] && b == r[:oldb]

    end

    ap the_t
    #puts "#{r[:olda]} #{r[:oldb]} #{r[:a]} #{r[:b]}"
    fixyfixy(the_t, r[:a], r[:b]) if the_t
    ap the_t
    puts "--"
    #PORDENONE if !the_t
  else
    fixyfixy(s.marc["596"].first, r[:a], r[:b])
  end

  s.paper_trail_event = "Fix 596 #{r[:olda]} #{r[:oldb]}"
  s.save
end
