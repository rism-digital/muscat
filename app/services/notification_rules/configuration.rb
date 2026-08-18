module NotificationRules
  class Configuration
    VERSION = 1

    MODELS = %w[
      source
      work
      institution
      person
      holding
      inventory_item
      liturgical_feast
      place
      publication
      standard_term
      standard_title
      work_node
    ].freeze
    MODELS_WITH_ALL = (MODELS + ["all"]).freeze

    FIELDS = {
      "source" => %w[record_type std_title composer title shelf_mark lib_siglum follow owner],
      "work" => %w[title form notes composer follow owner],
      "institution" => %w[siglum full_name address place comments alternates notes follow owner],
      "person" => %w[full_name life_dates birth_place alternate_names alternate_dates display_name follow owner],
      "holding" => %w[lib_siglum shelf_mark follow owner],
      "inventory_item" => %w[source_id title composer page_info follow owner],
      "liturgical_feast" => %w[name notes alternate_terms viaf gnd follow owner],
      "place" => %w[name country district notes alternate_terms hierarchy tgn_id follow owner],
      "publication" => %w[short_name author title journal volume place date pages work_catalogue follow owner],
      "standard_term" => %w[term alternate_terms notes sub_topic viaf gnd follow owner],
      "standard_title" => %w[title notes alternate_terms sub_topic viaf gnd latin follow owner],
      "work_node" => %w[person_id title form notes composer ext_number ext_code follow owner],
      "all" => %w[follow]
    }.freeze

    OPERATORS = %w[equals starts_with ends_with contains glob].freeze
    EXACT_FIELDS = %w[follow owner record_type].freeze

    class << self
      def fields_for(model)
        FIELDS.fetch(model.to_s, [])
      end

      def autocomplete_for(model, field)
        return "user" if field.to_s == "follow"
        return "institution" if field.to_s == "lib_siglum" || (model.to_s == "institution" && field.to_s == "siglum")
        return "person" if model.to_s == "person" && field.to_s == "full_name"
        return "person" if field.to_s == "composer"

        nil
      end

      def to_h
        {
          version: VERSION,
          models: MODELS_WITH_ALL,
          fields: FIELDS,
          operators: OPERATORS,
          exact_fields: EXACT_FIELDS
        }
      end
    end
  end
end
