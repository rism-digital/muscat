
invalid = %w(
db
dc
dv
ef
ex
ff
Fr
fx
kx
pn
ri
sp
Wirkl
zx
)

Person.find_each do |p|
  saveme = false
  codes = []
  p.marc["400"].each do |t|
    t["j"].each do |tt|
      if invalid.include?(tt.content.strip)
        codes << tt.content
        tt.content = "xx"
        saveme = true
      end
    end
  end

  if saveme
    codes_str = codes.compact.sort.uniq.join(", ")
    p.paper_trail_event = "Change 400$j to xx from [#{codes_str}]"
    puts "#{p.id} Change 400$j to xx from [#{codes_str}]"
    p.save
  end

end

Person.find_each do |p|
  saveme = false
  p.marc["400"].each do |t|
    if t["j"].count == 0
      t.add_at(MarcNode.new("person", "j", "xx", nil), 0 )
      t.sort_alphabetically
      saveme = true
    end
  end

  if saveme
   # p.paper_trail_event = "Change 400$j to xx from [#{codes_str}]"
    puts "#{p.id} Add 400$j xx"
    PaperTrail.request(enabled: false) do
      p.save
    end
  end

end