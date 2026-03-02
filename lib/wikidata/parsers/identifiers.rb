# app/services/wikidata/parsers/identifiers.rb
# Extract common external identifiers for a person.

module Wikidata
  module Parsers
    module Identifiers
      include Base
      module_function

      PID_GND  = "P227"
      PID_VIAF = "P214"
      PID_SBN  = "P396"
      PID_RISM = "P5504"

      def extract(item_json)
        {
          "DNB"  => ids(item_json, PID_GND),
          "VIAF" => ids(item_json, PID_VIAF),
          "ICCU"  => ids(item_json, PID_SBN),
          "rism" => ids(item_json, PID_RISM)
        }.delete_if { |_k, v| v.empty? }
      end

      def ids(item_json, pid)
        Base.statements(item_json, pid)
            .map { |st| Base.value_content_string(st) }
            .compact
            .uniq
      end
    end
  end
end