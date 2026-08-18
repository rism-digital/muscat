require "notification_rule_schema"

module NotificationRules
  class Configuration
    VERSION = 1

    OPERATORS = %w[equals starts_with ends_with contains glob].freeze

    class << self
      def to_h
        {
          version: VERSION,
          models: NotificationRuleSchema::MODELS_WITH_ALL,
          fields: NotificationRuleSchema::FIELDS,
          operators: OPERATORS,
          exact_fields: NotificationRuleSchema::EXACT_FIELDS
        }
      end
    end
  end
end
