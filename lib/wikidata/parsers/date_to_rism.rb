# app/services/wikidata/parsers/date_to_rism.rb
# Convert Wikidata birth/death time strings into a RISM 100$d string.
#
# Public API:
#   h = Wikidata::Parsers::DateToRism.get_dates(person_item_json)
#   # => { date_b: "+1616-00-00T00:00:00Z", date_d: "+1676-00-00T00:00:00Z" } or nil
#
#   Wikidata::Parsers::DateToRism.wikidata2rism(h)
#   # => "1600p-1600p" (per current mapping rules) or nil
#
# Notes:
# - This intentionally returns only the raw time strings in get_dates.
# - Precision/qualifiers can be added later if needed; current mapping is based on the string shape.

module Wikidata
  module Parsers
    module DateToRism
      include Base
      module_function

      PID_DATE_OF_BIRTH = "P569"
      PID_DATE_OF_DEATH = "P570"

      QID_GREGORIAN = "Q1985727"
      QID_JULIAN = "Q1985786"

      def extract_qid(input)
        input.to_s[/Q\d+/]
      end

      # Extract raw Wikidata time strings for birth/death.
      #
      # Returns:
      #   { date_b: "+YYYY-..T..Z", date_d: "+YYYY-..T..Z" }
      # If one side is missing, that key is nil.
      # Returns nil only if BOTH are missing/unavailable.
      def get_dates(item_json)
        b = Base.best_statement(item_json, PID_DATE_OF_BIRTH)
        d = Base.best_statement(item_json, PID_DATE_OF_DEATH)

        date_b, type_b = time_string_from_statement(b)
        date_d, type_d = time_string_from_statement(d)

        return nil if date_b.nil? && date_d.nil?
        {
          date_b: date_b, 
          date_d: date_d, 
          type_b: type_b,
          type_d: type_d,
        }
      end

      # Convert {date_b:, date_d:} to a RISM 100$d life-date string.
      #
      # Rules implemented (current):
      # - Exact year => "1879"
      # - YYYY-00-00 => century_start + "p" (after), e.g. 1616-00-00 => "1600p"
      # - YYYY-MM-00 => year + "c" (not exact)
      # - Missing death => "*" suffix
      # - Missing birth => "+" suffix
      #
      # Returns nil if input nil or both dates missing.
      def wikidata2rism(date_hash)
        return nil unless date_hash.is_a?(Hash)

        date_b = date_hash[:date_b] || date_hash["date_b"]
        date_d = date_hash[:date_d] || date_hash["date_d"]

        return nil if date_b.nil? && date_d.nil?

        b_tok = token_from_time_string(date_b)
        d_tok = token_from_time_string(date_d)

        extra = [date_hash[:type_b].to_s, date_hash[:type_d].to_s].join(", ")

        return nil if b_tok.nil? && d_tok.nil?
        return "#{b_tok}* (#{extra})" if b_tok && d_tok.nil?
        return "#{d_tok}+ (#{extra})" if d_tok && b_tok.nil?

        "#{b_tok}-#{d_tok} (#{extra})"
      end

      # ---- internals ----

      # Extracts "+YYYY-..T..Z" from a P569/P570 statement if present, else nil.
      def time_string_from_statement(statement)
        content = Base.value_content_hash(statement)
        return nil unless content.is_a?(Hash)

        calendar_qid = extract_qid(content["calendarmodel"])
        calendar = :unknown
        calendar = :gregorian if calendar_qid == QID_GREGORIAN
        calendar = :julian if calendar_qid == QID_JULIAN

        return content["time"].to_s, calendar      
      end

      # Converts a Wikidata time string into a RISM token without "*" / "+".
      def token_from_time_string(time_str)
        return nil unless time_str.is_a?(String)

        year, month, day = parse_time_ymd(time_str)
        return nil unless year

        # YYYY-00-00 -> century start + "p"
        if month.nil? && day.nil?
          century_start = (year / 100) * 100
          return "#{century_start}p"
        end

        # YYYY-MM-00 -> year + "c"
        if month && day.nil?
          return "#{year}c"
        end

        # full date -> exact year
        year.to_s
      end

      # Parses "+1616-00-00T..." into [year, month_or_nil, day_or_nil]
      def parse_time_ymd(time_str)
        m = /\A([+-])(\d{4,})-(\d{2})-(\d{2})T/.match(time_str)
        return [nil, nil, nil] unless m

        sign = m[1]
        year = m[2].to_i
        month_i = m[3].to_i
        day_i = m[4].to_i

        year = -year if sign == "-"
        month = month_i.zero? ? nil : month_i
        day   = day_i.zero? ? nil : day_i

        [year, month, day]
      end
    end
  end
end