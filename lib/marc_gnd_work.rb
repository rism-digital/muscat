class MarcGndWork < Marc
  def initialize(source = nil, model = "gnd_work")
    super(model, source)
  end

  def to_internal

    un_gnd("100", "t")
    un_gnd("400", "t")
    un_gnd("500", "t")

  end

  def to_external(created_at = nil, updated_at = nil, versions = nil, holdings = false, deprecated_ids = true)
    
    gndize("100", "t")
    gndize("400", "t")
    gndize("500", "t")

  end

  private

  def wrap_article(line)
    # Wrap the word before @ with U+0098 … U+009C, drop the @, keep spacing/words.
    line.gsub(/(\p{L}[\p{L}’']*)\s+@(?=\p{L})/u) { "\u{0098}#{$1}\u{009C} " }
  end

  def unwrap_and_mark(line)
    # Find:  U+0098 <article> U+009C <spaces> <next word>
    # Make:  <article> <spaces> @<next word>
    line.gsub(/\u{0098}(\p{L}[\p{L}’']*)\u{009C}(\s*)(?=\p{L})/u) do
      "#{$1}#{$2}@"
    end
  end

  def un_gnd(tag, subtag)
    self[tag].each do |t|
      t[subtag].each do |tt|
        tt.content = unwrap_and_mark(tt.content) if tt && tt.content
      end
    end
  end

  def gndize(tag, subtag)
    self[tag].each do |t|
      t[subtag].each do |tt|
        tt.content = wrap_article(tt.content) if tt && tt.content
      end
    end
  end

end
