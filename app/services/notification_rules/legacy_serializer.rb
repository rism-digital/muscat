module NotificationRules
  class LegacySerializer
    class << self
      def call(document)
        document = document.deep_stringify_keys
        generated = Array(document["rules"]).map { |rule| serialize_rule(rule) }
        (generated.compact + Array(document["legacy_lines"]).map(&:to_s).reject(&:blank?)).join("\n")
      end

      private

      def serialize_rule(rule)
        model = rule["model"].to_s
        tokens = []
        tokens << model unless %w[source all].include?(model)

        Array(rule["conditions"]).each do |condition|
          pattern = operator_to_pattern(condition["operator"], condition["value"].to_s)
          tokens << %(#{condition["field"]}:"#{pattern}")
        end

        tokens << "exclude:mine" if rule.dig("exclude", "own_changes")
        tokens.join(" ")
      end

      def operator_to_pattern(operator, value)
        case operator.to_s
        when "starts_with" then "#{value}*"
        when "ends_with" then "*#{value}"
        when "contains" then "*#{value}*"
        else value
        end
      end
    end
  end
end
