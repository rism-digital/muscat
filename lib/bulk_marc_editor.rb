# Configuration and record editing shared by the form and background job.
class BulkMarcEditor
  class InvalidOperation < ArgumentError; end

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

  # Lists remain suggestions: administrators can also enter unlisted values.
  # Include template-specific lists because a folder may contain several types.
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

  def validate_operations(operations)
    raise InvalidOperation, "Supply at least one operation" unless operations.is_a?(Array) && operations.any?

    operations.map do |input|
      raise InvalidOperation, "Invalid operation" unless input.is_a?(Hash)

      operation = input.stringify_keys.slice("action", "tag", "subfield", "target", "value", "old_value", "match_subfield", "match_value")
      raise InvalidOperation, "Invalid field value" unless operation.values.all? { |value| value.is_a?(String) }
      tag = operation["tag"]
      subfield = operation["subfield"]
      raise InvalidOperation, "Unknown tag or subfield" unless marc_config.has_tag?(tag) && marc_config.has_subfield?(tag, subfield)
      raise InvalidOperation, "Choose Add value or Change value" unless %w[add change].include?(operation["action"])
      raise InvalidOperation, "Enter a non-empty new value" if operation["value"].to_s.strip.empty?

      if operation["action"] == "add"
        raise InvalidOperation, "Invalid add target" unless %w[new all matching].include?(operation["target"])
        if operation["target"] == "matching"
          unless marc_config.has_subfield?(tag, operation["match_subfield"]) && operation.key?("match_value")
            raise InvalidOperation, "Choose a condition subfield and value"
          end
        end
        if operation["target"] == "new" && !marc_config.is_tagless?(tag)
          master = marc_config.get_master(tag)
          unless master == subfield || marc_config.master_optional?(tag)
            raise InvalidOperation, "A new #{tag} must include its master subfield $#{master}; add this subfield to existing tags instead"
          end
        end
      elsif !operation.key?("old_value")
        raise InvalidOperation, "Enter the old value"
      end
      operation
    end
  end

  # Returns whether this record changed. The job saves only after all operations
  # succeed, so a conflicting operation cannot partially update a record.
  def apply(record, operations)
    changed = false
    operations.each do |operation|
      changed = apply_operation(record.marc, operation) || changed
    end
    changed
  end

  def preview(record, operations)
    # instantiate supplies an independent MARC cache and preserves model-specific
    # constructor attributes, without invoking save callbacks or writing anything.
    copy = record.class.instantiate(record.attributes.deep_dup)
    before = record.marc.deep_copy
    changed = apply(copy, operations)
    after = copy.marc
    {
      id: record.id, title: record.respond_to?(:full_name) ? record.full_name : record.try(:name),
      status: changed ? :changed : :unchanged,
      tags: changed ? VersionChecker.compare_marc(before, after.deep_copy, tag_names: operations.map { |operation| operation["tag"] }) : [],
      before: before.to_marc, after: after.to_marc
    }
  rescue InvalidOperation => error
    { id: record.id, title: record.try(:name), status: :invalid, error: error.message }
  end

  def operation_summary(operation)
    field = "#{operation['tag']}#{operation['subfield'].empty? ? '' : " $#{operation['subfield']}"}"
    if operation["action"] == "change"
      "In #{field}, replace #{operation['old_value'].inspect} with #{operation['value'].inspect}."
    else
      target = case operation["target"]
      when "new" then "a new tag"
      when "all" then "all existing tag occurrences"
      when "matching" then "tag occurrences where $#{operation['match_subfield']} equals #{operation['match_value'].inspect}"
      end
      "Add #{field} = #{operation['value'].inspect} to #{target}."
    end
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

  def apply_operation(marc, operation)
    tag, subfield, value = operation.values_at("tag", "subfield", "value")
    tags = marc[tag].to_a
    tagless = marc_config.is_tagless?(tag)
    if operation["action"] == "add" && operation["target"] == "new"
      if tags.any? && !marc_config.multiples_allowed?(tag)
        raise InvalidOperation, "#{tag} is not repeatable and already exists"
      end
      if tagless
        marc.root.add_at(MarcNode.new(marc_config.get_model, tag, value, nil), marc.get_insert_position(tag))
      else
        marc.add_tag_with_subfields(tag, subfield => value)
      end
      return true
    end

    if operation["action"] == "add" && operation["target"] == "matching"
      tags = tags.select do |node|
        values = tagless ? [node] : node[operation["match_subfield"]]
        values.any? { |child| child.content.to_s == operation["match_value"] }
      end
    end
    changed = false
    tags.each do |node|
      children = tagless ? [node] : node[subfield]
      if operation["action"] == "change"
        children.each do |child|
          next unless child.content.to_s == operation["old_value"] && child.content.to_s != value

          child.content = value
          changed = true
        end
      else
        next if children.any? { |child| child.content.to_s == value }
        if tagless || (children.any? && !marc_config.multiples_allowed?(tag, subfield))
          raise InvalidOperation, "#{tag} $#{subfield} is not repeatable and already has a value"
        end
        node.add(MarcNode.new(marc_config.get_model, subfield, value, nil))
        node.sort_alphabetically
        changed = true
      end
    end
    changed
  end
end
