# frozen_string_literal: true

module AggressivelyStrip
  # Build regexes from Unicode codepoints so we don't rely on \uXXXX inside /.../
  SPACE_LIKE_RANGES = [
    0x00A0,           # NBSP
    0x1680,           # OGHAM SPACE MARK
    (0x2000..0x200A), # EN QUAD..HAIR SPACE (incl 0x2007)
    0x2028,           # LINE SEPARATOR
    0x2029,           # PARAGRAPH SEPARATOR
    0x202F,           # NARROW NBSP
    0x205F,           # MEDIUM MATHEMATICAL SPACE
    0x3000            # IDEOGRAPHIC SPACE
  ].freeze

  INVISIBLE_CODES = [
    0x180E, # MONGOLIAN VOWEL SEPARATOR (deprecated but appears)
    0x200B, # ZERO WIDTH SPACE
    0x200C, # ZERO WIDTH NON-JOINER
    0x200D, # ZERO WIDTH JOINER
    0x2060, # WORD JOINER
    0xFEFF, # BOM / ZERO WIDTH NO-BREAK SPACE
    0x200E, # LTR MARK
    0x200F  # RTL MARK
  ].freeze

  SPACE_LIKE = Regexp.union(
    SPACE_LIKE_RANGES.map do |x|
      if x.is_a?(Range)
        /[#{[x.begin].pack("U")}-#{[x.end].pack("U")}]/u
      else
        [x].pack("U")
      end
    end
  )

  INVISIBLE = Regexp.union(INVISIBLE_CODES.map { |cp| [cp].pack("U") })

  refine String do
    def aggressively_strip
      s = dup
      s.gsub!(AggressivelyStrip::SPACE_LIKE, " ")
      s.gsub!(AggressivelyStrip::INVISIBLE, "")
      s
    end

    def aggressively_strip!
      replace(aggressively_strip)
    end
  end
end
