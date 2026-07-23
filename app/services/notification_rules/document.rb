module NotificationRules
  class Document
    MAX_RULES = 50
    MAX_CONDITIONS = 10
    MAX_VALUE_LENGTH = 500
    MAX_LEGACY_LINES = 100

    attr_reader :errors

    def initialize(value)
      @value = parse(value)
      @errors = []
      validate
    end

    def valid?
      errors.empty?
    end

    def to_h
      @value
    end

    private

    def parse(value)
      parsed = value.is_a?(String) ? JSON.parse(value) : value
      parsed = {} unless parsed.is_a?(Hash)
      parsed.deep_stringify_keys
    rescue JSON::ParserError
      @parse_error = true
      {}
    end

    def validate
      if @parse_error
        errors << "is not valid JSON"
        return
      end

      errors << "has an unsupported version" unless @value["version"] == Configuration::VERSION

      rules = @value["rules"]
      unless rules.is_a?(Array)
        errors << "must contain a rules list"
        return
      end

      errors << "cannot contain more than #{MAX_RULES} rules" if rules.length > MAX_RULES
      rules.each_with_index { |rule, index| validate_rule(rule, index) }
      validate_legacy_lines
    end

    def validate_rule(rule, index)
      unless rule.is_a?(Hash)
        errors << "rule #{index + 1} is invalid"
        return
      end

      model = rule["model"].to_s
      errors << "rule #{index + 1} has an unsupported record type" unless Configuration::MODELS_WITH_ALL.include?(model)

      conditions = rule["conditions"]
      unless conditions.is_a?(Array) && conditions.any?
        errors << "rule #{index + 1} must have at least one condition"
        return
      end

      errors << "rule #{index + 1} cannot have more than #{MAX_CONDITIONS} conditions" if conditions.length > MAX_CONDITIONS
      conditions.each_with_index { |condition, condition_index| validate_condition(condition, model, index, condition_index) }

      exclude = rule["exclude"]
      if exclude.present? && (!exclude.is_a?(Hash) || ![true, false].include?(exclude["own_changes"]))
        errors << "rule #{index + 1} has an invalid exclusion"
      end
    end

    def validate_condition(condition, model, rule_index, condition_index)
      label = "rule #{rule_index + 1}, condition #{condition_index + 1}"
      unless condition.is_a?(Hash)
        errors << "#{label} is invalid"
        return
      end

      field = condition["field"].to_s
      operator = condition["operator"].to_s
      value = condition["value"].to_s

      errors << "#{label} has an unsupported field" unless Configuration.fields_for(model).include?(field)
      errors << "#{label} has an unsupported operator" unless Configuration::OPERATORS.include?(operator)
      if Configuration::EXACT_FIELDS.include?(field) && operator != "equals"
        errors << "#{label} only supports exact matching"
      end
      errors << "#{label} needs a value" if value.blank?
      errors << "#{label} is too long" if value.length > MAX_VALUE_LENGTH
      errors << "#{label} cannot contain a colon, quote, or line break" if value.match?(/[:"\r\n]/)
    end

    def validate_legacy_lines
      lines = @value["legacy_lines"]
      unless lines.nil? || lines.is_a?(Array)
        errors << "legacy rules must be a list"
        return
      end

      errors << "cannot contain more than #{MAX_LEGACY_LINES} legacy rules" if lines&.length.to_i > MAX_LEGACY_LINES
      Array(lines).each do |line|
        errors << "legacy rules must contain one line each" if line.to_s.match?(/[\r\n]/)
      end
    end
  end
end
