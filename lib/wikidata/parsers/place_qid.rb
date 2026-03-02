# app/services/wikidata/parsers/place_qid.rb
# Convert a place Q-id item JSON into a place hash:
# - English preferred name + aliases (other spellings)
# - admin context (country + P131 chain)
# - Getty TGN id if present

module Wikidata
  module Parsers
    module PlaceQid
      include Base
      module_function

      PID_LOCATED_IN_ADMIN = "P131"
      PID_COUNTRY          = "P17"
      PID_INSTANCE_OF      = "P31"
      PID_GETTY_TGN        = "P1667"

      # Extract a normalized place hash from a place item JSON.
      # admin_items: optional array of already-fetched admin items in chain (see builder usage).
      def extract_place(place_item_json, lang: "en", include_all_aliases: false)
        place = {
          qid: place_item_json["id"],
          name: Base.label(place_item_json, lang: lang),
          #aliases_en: Base.aliases(place_item_json, lang: lang),
          getty_tgn: external_ids(place_item_json, PID_GETTY_TGN)
        }

        place[:aliases_all] = Base.aliases_all(place_item_json) if include_all_aliases

        # Country Q-id (resolved elsewhere by builder if desired)
        country_qid = item_qid(place_item_json, PID_COUNTRY)
        place[:country_qid] = country_qid if country_qid

        # First admin parent (resolved/expanded elsewhere)
        admin_qid = item_qid(place_item_json, PID_LOCATED_IN_ADMIN)
        place[:admin_parent_qid] = admin_qid if admin_qid

        place
      end

      # Build a node for an admin item (label, aliases, and types).
      def extract_admin_node(admin_item_json, lang: "en")
        type_qids = item_qids(admin_item_json, PID_INSTANCE_OF)

        {
          qid: admin_item_json["id"],
          name: Base.label(admin_item_json, lang: lang),
          #aliases_en: Base.aliases(admin_item_json, lang: lang),
          type_qids: type_qids
        }
      end

      # --- low-level value extractors ---

      def item_qid(item_json, pid)
        st = Base.best_statement(item_json, pid)
        Base.value_content_string(st)
      end

      def item_qids(item_json, pid)
        Base.statements(item_json, pid).map { |st| Base.value_content_string(st) }.compact.uniq
      end

      def external_ids(item_json, pid)
        Base.statements(item_json, pid).map { |st| Base.value_content_string(st) }.compact.uniq
      end
    end
  end
end