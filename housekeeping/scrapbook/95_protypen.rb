prot = {
  "*z26"=>["303", "z"],
  "*y35"=>[nil, "y"],
  "*y25"=>["308", "y"],
  "*y23"=>["300", "y"],
  "*x25"=>["308", "x"],
  "*u25"=>["308", "u"],
  "*t33"=>["304", "t"],
  "*t28"=>[nil, "t"],
  "*t26"=>["303", "t"],
  "*s33"=>["304", "s"],
  "*s26"=>["303", "s"],
  "*r33"=>["304", "r"],
  "*r26"=>["303", "r"],
  "*r24"=>["302", "r"],
  "*p33"=>["304", "p"],
  "*p26"=>["303", "p"],
  "*o62"=>[nil, "o"],
  "*o28"=>[nil, "o"],
  "*o24"=>["302", "o"],
  "*N33"=>["304", "N"],
  "*n33"=>["304", "n"],
  "*m33"=>["304", "m"],
  "*M33"=>["304", "M"],
  "*m32"=>[nil, "m"],
  "*m27"=>["030C", "m"],
  "*m26"=>["303", "m"],
  "*m25"=>["308", "m"],
  "*m24"=>["302", "m"],
  "*l33"=>["304", "l"],
  "*l26"=>["303", "l"],
  "*j26"=>["303", "j"],
  "*g26"=>["303", "g"],
  "*g25"=>["308", "g"],
  "*f64"=>[nil, "f"],
  "*f63"=>[nil, "f"],
  "*f53"=>[nil, "f"],
  "*e25"=>["308", "e"],
  "*e23"=>["300", "e"],
  "*e22"=>["301", "e"],
  "*D33"=>["304", "D"],
  "*d27"=>["010F", nil],
  "*d26"=>["303", "d"],
  "*c33"=>["304", "c"],
  "*c26"=>["303", "c"],
  "*c22"=>["301", "c"],
  "*a45"=>["00E6", nil],
  "*a33"=>["304", "a"],
  "*485"=>["266E", nil],
  "*486"=>["266F", nil],
  "*487"=>["266D", nil],
  "*362"=>["002A", nil],
  "*378"=>["002B", nil],
}

def add_combining_char(base_char, unicode_val)
  combining_char = unicode_val.hex.chr("UTF-8")  # Convert Unicode value to combining char
  combined_char = base_char + combining_char
  return combined_char
end

subst = {}

prot.each do |k, v|
  next if v[0] == nil
  subst[k] = add_combining_char(v[1], v[0]) if v[1]
  subst[k] = v[0].hex.chr("UTF-8") if !v[1]
end

File.open("housekeeping/scrapbook/protypen_subsitute.txt") do |f|
  f.each_line do |line|
    parts = line.split("\t")
    if subst.keys.include?(parts[0])
      puts parts[1].gsub(parts[0], subst[parts[0]])
    else
      puts parts[1]
    end
  end
end

=begin
subs = {}
pt.each do |k,v|
  subs[k] = v.hex.chr('UTF-8')
end

def find_pattern(s)
  pattern = /\b(\S*?(\*[A-Za-z0-9]\d{2})\S*)\b/
  if m = s.match(pattern)
    return [m[1], m[2]]
  else
    return nil
  end
end

#pb = ProgressBar.new(Source.all.count)
Source.find_in_batches do |batch|

  batch.each do |s|
		
    s.marc.load_source false

    s.marc.all_tags.each do |tag|

      tag.each do |subt|
        next if !subt.content
        r = find_pattern(subt.content)
        next if !r
        subbed_word = r[0].gsub(r[1], subs[r[1]]) if subs.keys.include?(r[1])
        puts "#{s.id}\t#{tag.tag}\t#{r[1]}\t#{r[0]}\t#{subbed_word}" if r
      end
    end
        
    #pb.increment!

  end

end

#puts all.sort.uniq
=end