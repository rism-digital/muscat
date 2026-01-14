
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