# app/services/wikidata/parsers/base.rb
# Shared helpers for parsing Wikidata REST item JSON.

module Wikidata
  module Parsers
    module Base
      module_function

      # Return statements array for property id (Pxxx).
      def statements(item_json, pid)
        st = item_json["statements"]
        return [] unless st.is_a?(Hash)

        arr = st[pid]
        arr.is_a?(Array) ? arr : []
      end

      # Choose a best statement:
      # - prefer rank=="preferred"
      # - otherwise first statement
      def best_statement(item_json, pid)
        stmts = statements(item_json, pid).select { |s| s.is_a?(Hash) }
        preferred = stmts.select { |s| s["rank"] == "preferred" }
        (preferred.any? ? preferred : stmts).first
      end

      # In your REST output, wikibase-item and many identifier values are strings in value.content.
      def value_content_string(statement)
        return nil unless statement.is_a?(Hash)
        v = statement["value"]
        return nil unless v.is_a?(Hash)
        content = v["content"]
        content.is_a?(String) ? content : nil
      end

      # For time-valued statements, value.content is a Hash with "time" and maybe "precision".
      def value_content_hash(statement)
        return nil unless statement.is_a?(Hash)
        v = statement["value"]
        return nil unless v.is_a?(Hash)
        content = v["content"]
        content.is_a?(Hash) ? content : nil
      end

      # Labels: item_json["labels"] is a Hash of lang => string.
      def label(item_json, lang: "en")
        labels = item_json["labels"]
        return nil unless labels.is_a?(Hash)
        labels[lang] || labels["en"] || labels.values.first
      end

      # Aliases: item_json["aliases"][lang] often array of strings in REST output.
      def aliases(item_json, lang: "en")
        all = item_json["aliases"]
        return [] unless all.is_a?(Hash)
        arr = all[lang] || all["en"] || []
        Array(arr).map do |a|
          if a.is_a?(String)
            a
          elsif a.is_a?(Hash)
            a["value"] || a["text"] || a["label"]
          end
        end.compact.uniq
      end

      def aliases_all(item_json)
        all = item_json["aliases"]
        return {} unless all.is_a?(Hash)

        all.each_with_object({}) do |(lng, arr), h|
          vals = Array(arr).map do |a|
            if a.is_a?(String)
              a
            elsif a.is_a?(Hash)
              a["value"] || a["text"] || a["label"]
            end
          end.compact.uniq
          h[lng] = vals if vals.any?
        end
      end
    end
  end
end