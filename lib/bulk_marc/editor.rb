module BulkMarc
  # Validates operations and transforms one record's MARC without saving it.
  class Editor
    attr_reader :configuration

    delegate :model, :marc_config, :editor_profile, to: :configuration

    def initialize(configuration)
      @configuration = configuration
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

    # Save only after every operation succeeds, to avoid partial record updates.
    def apply(record, operations)
      changed = false
      operations.each do |operation|
        changed = apply_operation(record.marc, operation) || changed
      end
      changed
    end

    private

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
end
