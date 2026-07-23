module NotificationRules
  class LegacyImporter
    class << self
      def call(notifications)
        rules = []
        legacy_lines = []

        notifications.to_s.each_line do |raw_line|
          line = raw_line.strip
          next if line.blank?

          rule = import_line(line)
          rule ? rules << rule : legacy_lines << line
        end

        {
          "version" => Configuration::VERSION,
          "rules" => rules,
          "legacy_lines" => legacy_lines
        }
      end

      private

      def import_line(line)
        model, parsed_conditions = NotificationMatcher.parse_line(line)
        model = model.to_s
        return unless Configuration::MODELS_WITH_ALL.include?(model)
        return if parsed_conditions.blank?

        own_changes = parsed_conditions.any? do |item|
          item[:property].to_s == "exclude" && item[:pattern].to_s == "mine"
        end

        conditions = parsed_conditions.filter_map do |item|
          field = item[:property].to_s
          next if field == "exclude"
          return unless Configuration.fields_for(model).include?(field)
          return if Configuration::EXACT_FIELDS.include?(field) && item[:pattern].to_s.include?("*")

          operator, value = pattern_to_operator(item[:pattern].to_s)
          {
            "field" => field,
            "operator" => operator,
            "value" => value
          }
        end

        return if conditions.blank?

        rule = { "model" => model, "conditions" => conditions }
        rule["exclude"] = { "own_changes" => true } if own_changes
        rule
      rescue StandardError
        nil
      end

      def pattern_to_operator(pattern)
        if pattern.start_with?("*") && pattern.end_with?("*") && pattern.count("*") == 2
          ["contains", pattern[1...-1]]
        elsif pattern.end_with?("*") && pattern.count("*") == 1
          ["starts_with", pattern[0...-1]]
        elsif pattern.start_with?("*") && pattern.count("*") == 1
          ["ends_with", pattern[1..]]
        elsif pattern.include?("*")
          ["glob", pattern]
        else
          ["equals", pattern]
        end
      end
    end
  end
end
