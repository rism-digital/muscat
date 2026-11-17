module BulkMarc
  # Samples folder contents, builds read-only diffs, and checks snapshot freshness.
  class Preview
    attr_reader :editor

    def initialize(editor)
      @editor = editor
    end

    # Capture the sample before generating diffs, then verify it before saving the draft.
    def self.prepare(folder, user, operations, sample_size: 10)
      editor = Editor.new(Configuration.new(folder.folder_model))
      preview = new(editor)
      operations = editor.validate_operations(operations)
      size = BulkMarcEditDraft::SAMPLE_SIZES.include?(sample_size.to_i) ? sample_size.to_i : 10
      membership = membership_for(folder)
      records = records_for(folder)
      sample = records.reorder(:id).limit(size).to_a
      draft = BulkMarcEditDraft.new(
        folder_id: folder.id, requesting_user_id: user.id, operations: operations,
        sample_size: size, target_count: records.count, expires_at: 1.hour.from_now,
        membership_digest: membership, configuration_digest: configuration_for(editor),
        sample_snapshot: sample.map { |record| { "id" => record.id, "fingerprint" => fingerprint(record) } }
      )
      rows = sample.map { |record| preview.record(record, operations) }
      draft.ensure_fresh!(folder)
      draft.save!
      [draft, rows]
    end

    def self.fresh?(draft, folder)
      editor = Configuration.new(folder.folder_model)
      return false unless draft.membership_digest == membership_for(folder) &&
        draft.configuration_digest == configuration_for(editor) &&
        draft.target_count == records_for(folder).count

      records = folder.folder_model.where(id: draft.sample_snapshot.map { |entry| entry["id"] }).index_by(&:id)
      draft.sample_snapshot.all? do |entry|
        record = records[entry["id"]]
        record && fingerprint(record) == entry["fingerprint"]
      end
    end

    def self.records_for(folder)
      ids = folder.folder_items.where(item_type: folder.folder_type).select(:item_id)
      folder.folder_model.where(id: ids)
    end

    def self.membership_for(folder)
      digest = Digest::SHA256.new
      digest << folder.folder_type
      folder.folder_items.find_each do |item|
        digest << "#{item.id}:#{item.item_type}:#{item.item_id};"
      end
      digest.hexdigest
    end

    def self.fingerprint(record)
      Digest::SHA256.hexdigest(record.attributes.sort.to_h.to_json)
    end

    def self.configuration_for(editor)
      Digest::SHA256.hexdigest(editor.marc_config.to_yaml + editor.editor_profile.options_config.to_yaml)
    end

    def record(record, operations)
      # instantiate supplies an independent MARC cache and preserves model-specific
      # constructor attributes, without invoking save callbacks or writing anything.
      copy = record.class.instantiate(record.attributes.deep_dup)
      before = record.marc.deep_copy
      changed = editor.apply(copy, operations)
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
  end
end
