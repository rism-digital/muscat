module NotificationRuleSchema
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
  }.transform_values(&:freeze).freeze

  SPECIAL_FIELDS = {
    "source" => %w[lib_siglum record_type shelf_mark follow owner],
    "work" => %w[composer follow owner],
    "institution" => %w[follow owner],
    "person" => %w[follow owner],
    "holding" => %w[follow owner],
    "inventory_item" => %w[follow owner],
    "liturgical_feast" => %w[follow owner],
    "place" => %w[follow owner],
    "publication" => %w[follow owner],
    "standard_term" => %w[follow owner],
    "standard_title" => %w[follow owner],
    "work_node" => %w[follow owner]
  }.transform_values(&:freeze).freeze

  EXACT_FIELDS = %w[follow owner record_type].freeze

  class << self
    def fields_for(model)
      FIELDS.fetch(model.to_s, [])
    end

    def special_fields_for(model)
      SPECIAL_FIELDS.fetch(model.to_s, [])
    end

    def model_name_for(record_or_class)
      klass = record_or_class.is_a?(Class) ? record_or_class : record_or_class.class
      klass.model_name.element
    end
  end
end
