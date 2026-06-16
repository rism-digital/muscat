# app/services/wikidata/parsers/person_core.rb
# Extract core person fields (label, aliases, gender, occupations, place Q-ids, etc.)
# from the person item JSON.

module Wikidata
  module Parsers
    module PersonCore
      include Base
      module_function

      PID_SEX_OR_GENDER  = "P21"
      PID_OCCUPATION     = "P106"

      PID_PLACE_OF_BIRTH = "P19"
      PID_PLACE_OF_DEATH = "P20"
      PID_RESIDENCE      = "P551"
      PID_WORK_LOCATION  = "P937"

      PID_FAMILY_NAME    = "P734"
      PID_GIVEN_NAME     = "P735"

      # Wikidata Q-ids for gender
      QID_MALE   = "Q6581097"
      QID_FEMALE = "Q6581072"

      def extract(item_json, lang: "en")
        {
          qid: item_json["id"],
          label: Base.label(item_json, lang: lang),
          aliases: Base.aliases(item_json, lang: lang),

          family_name_qid: item_qid(item_json, PID_FAMILY_NAME),
          given_name_qid: item_qid(item_json, PID_GIVEN_NAME),

          gender: extract_gender(item_json),
          occupation_qids: item_qids(item_json, PID_OCCUPATION),

          place_of_birth_qid: item_qid(item_json, PID_PLACE_OF_BIRTH),
          place_of_death_qid: item_qid(item_json, PID_PLACE_OF_DEATH),
          residences_qids: item_qids(item_json, PID_RESIDENCE),
          work_locations_qids: item_qids(item_json, PID_WORK_LOCATION),
        }
      end

      # Map Wikidata P21 to one of: "male", "female", "unknown"
      def extract_gender(item_json)
        qid = item_qid(item_json, PID_SEX_OR_GENDER)

        case qid
        when QID_MALE   then "male"
        when QID_FEMALE then "female"
        else "unknown"
        end
      end

      def item_qid(item_json, pid)
        st = Base.best_statement(item_json, pid)
        Base.value_content_string(st)
      end

      def item_qids(item_json, pid)
        Base.statements(item_json, pid).map { |st| Base.value_content_string(st) }.compact.uniq
      end
    end
  end
end