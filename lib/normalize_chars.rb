module NormalizeChars
  # Fix typographic and exotic variations of standard chars, that
  # creates different and duplicated forms of the same text.

  NORMALIZE_CHARS = {
    ' ' => [ # space
      "\t", # Unicode codepoint 9, CHARACTER TABULATION
      ' ',  # Unicode codepoint 160, NO-BREAK SPACE
      '­',  # Unicode codepoint 173, SOFT HYPHEN
      '‎',  # Unicode codepoint 8206, LEFT-TO-RIGHT MARK
      '&#13;',
      '&nbsp;',
    ],
    '-' => [ # dash
      '‐', # Unicode codepoint 8208, HYPHEN
      '‑', # Unicode codepoint 8209, NON-BREAKING HYPHEN
      '–', # Unicode codepoint 8211, EN DASH
      '—', # Unicode codepoint 8212, EM DASH
      '−', # Unicode codepoint 8722, MINUS SIGN
    ],
    '"' => [ # double quote
      '“', # Unicode codepoint 8220, LEFT DOUBLE QUOTATION MARK
      '”', # Unicode codepoint 8221, RIGHT DOUBLE QUOTATION MARK
    ],
    "'" => [ # apostroph or single quote
      '`', # Unicode codepoint 96, GRAVE ACCENT
      '´', # Unicode codepoint 180, ACUTE ACCENT
      '‘', # Unicode codepoint 8216, LEFT SINGLE QUOTATION MARK
      '’', # Unicode codepoint 8217, RIGHT SINGLE QUOTATION MARK
      '′', # Unicode codepoint 8242, PRIME
      '', # Unicode codepoint 146, PRIVATE USE TWO
    ],
    '«' => [ # typographic open quote
      '<<',
      '&lt;&lt;',
    ],
    '»' => [ # typographic close quote
      '>>',
      '&gt;&gt;',
    ],
    'l·l' => [ # Catalan geminate el
      'l.l',
      'l•l',
      'l&#61655;l',
    ],
    'œ' => [ # oe ligature
      '&oelig;',
    ],
  }.freeze

  def normalize_chars!
=begin
    if self.respond_to? :marc_source
      normalized = self.marc_source
    elsif self.respond_to? :name
      normalized = self.name
    elsif self.respond_to? :term
      normalized = self.term
    elsif self.respond_to? :title
      normalized = self.title
    else
      return
    end

    return if normalized.nil?
=end

    self.class.columns_hash.each do |attr_name, col|
      next if !self[attr_name]
      
      if col.type == :string || col.type == :text
        #self[attr_name] = value&.strip if value.respond_to?(:strip)

        NORMALIZE_CHARS.each do |good_char, bad_chars|
          bad_chars.each do |bad_char|
            value = self[attr_name]
            self[attr_name] = value.gsub(bad_char, good_char)
          end
        end
      end
    end
#    NORMALIZE_CHARS.each do |good_char, bad_chars|
#      bad_chars.each do |bad_char|
#        normalized.gsub!(bad_char, good_char)
#      end
#    end
    ""
  end

end
