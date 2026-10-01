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


subs = {}
prot.each do |k, v|
  next if v[0] == nil
  subs[k] = add_combining_char(v[1], v[0]) if v[1]
  subs[k] = v[0].hex.chr("UTF-8") if !v[1]
end

p subs["*362"]
p subs["*378"]

exit 0

def find_patterns(string)
  matches = []

  string.to_enum(:scan, /\*[A-Za-z0-9]\d{2}/).each do
    match = Regexp.last_match
    word_start = match.begin(0)
    word_end = match.end(0)

    word_start -= 1 while word_start.positive? && string[word_start - 1] !~ /\s/
    word_end += 1 while word_end < string.length && string[word_end] !~ /\s/

    matches << [string[word_start...word_end], match[0]]
  end

  matches
end

Rails.application.eager_load!

marc_models = ApplicationRecord.descendants.select do |model|
  !model.abstract_class? && model.table_exists? && model.column_names.include?("marc_source")
end

marc_models.sort_by(&:name).each do |model|
  model.where.not(marc_source: nil).find_each do |record|
		
    record.marc.load_source false

    record.marc.all_tags.each do |tag|

      tag.each do |subt|
        next if !subt.content

        find_patterns(subt.content).each do |word, protypen|
          subbed_word = word.gsub(protypen, subs[protypen]) if subs.key?(protypen)
          puts "#{model.name}\t#{record.id}\t#{tag.tag}\t#{protypen}\t#{word}\t#{subbed_word}"
        end
      end
    end
  end
end
