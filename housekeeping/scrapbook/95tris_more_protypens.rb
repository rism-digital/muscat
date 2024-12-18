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
  "*q26"=>["303", "q"],
  "*Q26"=>["303", "Q"],
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


def find_pattern(s)
  pattern = /(\S*?(\*[A-Za-z0-9]\d{2})\S*)/
  #pattern = /\*([a-zA-Z0-9][0-9]{2})/
  return s.scan(pattern)
  #if matches = s.scan(pattern)
  #  return matches
  #else
  #  return nil
  #end
end

sheet = RODF::Spreadsheet.new
table = sheet.table("More Protypens")

header = table.row
header.cell("ID")
header.cell("Tag")
header.cell("Protypen")
header.cell("Word")
header.cell("Substitution")
header.cell("Skip")
header.cell("Phrase")

#pb = ProgressBar.new(Source.all.count)
Source.where('marc_source REGEXP "\\\*([a-zA-Z0-9][0-9]{2})"').each do |s|

#puts s.id
    s.marc.load_source false

    s.marc.all_tags.each do |tag|

      tag.each do |subt|
        next if !subt.content
        matches = find_pattern(subt.content)
        next if !matches || matches.count == 0
        matches.each do |word, protypen|
            puts "#{puts s.id} word: #{word} protypen: #{protypen}".yellow
            substitution = word.gsub(protypen, subst[protypen]) if subst.keys.include?(protypen)

            row = table.row
            row.cell(s.id)
            row.cell("#{tag.tag}$#{subt}")
            row.cell(protypen)
            row.cell(word)
            row.cell(substitution)
            row.cell("y") if !substitution || substitution.empty?
            row.cell("") if substitution && !substitution.empty?
            row.cell(subt.content)
        end
        subbed_word = "" #r[0].gsub(r[1], subs[r[1]]) if subs.keys.include?(r[1])
        #puts "#{s.id}\t#{tag.tag}\t#{r[1]}\t#{r[0]}\t#{subbed_word}" if r
      end
    end

end

sheet.write_to 'protypens.ods'

#puts all.sort.uniq