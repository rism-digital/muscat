module BulkMarc
  # Resolves MARC structure, editor labels, and all configured value choices.
  class Configuration
    attr_reader :model, :marc_config, :editor_profile

    def initialize(model)
      @model = model
      @editor_profile = EditorConfiguration.get_default_layout(model)
      @marc_config = model.new.marc.config if model && model.method_defined?(:marc)
      raise InvalidOperation, "This folder does not contain supported MARC records" unless @marc_config && @editor_profile
    end

    def fields
      result = []
      marc_config.each_tag do |tag|
        subfields = []
        marc_config.each_subtag(tag) do |code, _config|
          code = code.to_s
          label = editor_profile.has_sub_label?(tag, code) ? editor_profile.get_sub_label(tag, code) : code
          subfields << { code: code, label: code.empty? ? "Whole field" : "#{label} ($#{code})", choices: choices(tag, code) }
        end
        label = editor_profile.has_label?(tag) ? editor_profile.get_label(tag) : "MARC field"
        result << { code: tag, label: "#{tag} — #{label}", subfields: subfields }
      end
      result
    end

    # Lists include template-specific choices because folders may contain several record types.
    def choices(tag, subfield)
      options = editor_profile.options_config[tag] || {}
      field = (options.dig("layout", "fields") || []).assoc(subfield)
      params = field && field[1].is_a?(Hash) ? field[1] : {}
      tag_params = options["tag_params"] || {}
      groups = []
      if params["shared_codes"]
        groups << [nil, SharedCodes.get(params["shared_codes"])]
      elsif params["codes_reference"] || params["editor_partial"].to_s.include?("select_codes")
        reference = params["codes_reference"] || (params["editor_partial"] == "subfield_select_codes_grouped" ? "groups" : "codes")
        groups << [nil, tag_params[reference]]
        tag_params.each do |key, values|
          groups << [nil, values] if key.to_s.start_with?("#{reference}_") && !(values.is_a?(Hash) && values.key?("remove"))
        end
      else
        groups << [nil, params["values"]]
        (params["templates"] || {}).each_value { |values| groups << [nil, values] }
      end
      groups.flat_map { |group, values| choice_entries(values, group) }.uniq { |entry| entry[:value] }
    end

    private

    def choice_entries(values, group)
      return [] if values.nil?
      if values.is_a?(Hash)
        return values.flat_map { |name, entries| choice_entries(entries, choice_label(name)) }
      end
      Array(values).map do |entry|
        code = entry.is_a?(Hash) ? entry["code"] : entry
        label = entry.is_a?(Hash) ? I18n.t(entry["label"]) : choice_label(code)
        { value: code.to_s, label: label, group: group }
      end
    end

    def choice_label(code)
      editor_profile.has_label?(code) ? editor_profile.get_label(code) : code.to_s
    end
  end
end
