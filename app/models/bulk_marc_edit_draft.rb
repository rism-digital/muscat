class BulkMarcEditDraft < ApplicationRecord
  class StalePreview < StandardError; end

  SAMPLE_SIZES = [10, 25, 50, 100].freeze
  serialize :operations, coder: JSON
  serialize :sample_snapshot, coder: JSON

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

  # Captures the sample before generating diffs, so later writes cannot silently
  # turn an already rendered preview into approval for different record data.
  def self.prepare(folder, user, operations, sample_size: 10)
    editor = BulkMarcEditor.new(folder.folder_model)
    operations = editor.validate_operations(operations)
    size = SAMPLE_SIZES.include?(sample_size.to_i) ? sample_size.to_i : 10
    membership = membership_for(folder)
    records = records_for(folder)
    sample = records.reorder(:id).limit(size).to_a
    draft = new(
      folder_id: folder.id, requesting_user_id: user.id, operations: operations,
      sample_size: size, target_count: records.count, expires_at: 1.hour.from_now,
      membership_digest: membership, configuration_digest: configuration_for(editor),
      sample_snapshot: sample.map { |record| { "id" => record.id, "fingerprint" => fingerprint(record) } }
    )
    rows = sample.map { |record| editor.preview(record, operations) }
    draft.ensure_fresh!(folder)
    draft.save!
    [draft, rows]
  end

  def ensure_fresh!(folder)
    editor = BulkMarcEditor.new(folder.folder_model)
    fresh = membership_digest == self.class.membership_for(folder) &&
      configuration_digest == self.class.configuration_for(editor) &&
      target_count == self.class.records_for(folder).count
    if fresh
      records = folder.folder_model.where(id: sample_snapshot.map { |entry| entry["id"] }).index_by(&:id)
      fresh = sample_snapshot.all? do |entry|
        record = records[entry["id"]]
        record && self.class.fingerprint(record) == entry["fingerprint"]
      end
    end
    raise StalePreview, "Records or configuration changed since this preview. Refresh the preview before applying." unless fresh
  rescue BulkMarcEditor::InvalidOperation
    raise StalePreview, "The folder configuration changed. Refresh the preview before applying."
  end

  def ensure_reviewable!
    raise StalePreview, "This preview has already been confirmed." if confirmed_at
    raise StalePreview, "This preview expired. Generate a new preview before applying." if expires_at <= Time.current
  end

  def enqueue!(folder, user)
    with_lock do
      ensure_context!(folder.id, user.id, operations)
      ensure_reviewable!
      ensure_fresh!(folder)
      update!(confirmed_at: Time.current)
      Delayed::Job.enqueue(BulkMarcEditorJob.new(folder.id, operations, user.id, preview_draft_id: id))
    end
  end

  def start!(folder, user, job_operations)
    with_lock do
      ensure_context!(folder.id, user.id, job_operations)
      raise StalePreview, "This preview has not been confirmed, or has already started." unless confirmed_at && !started_at

      ensure_fresh!(folder)
      update!(started_at: Time.current)
    end
  end

  private

  def ensure_context!(expected_folder_id, expected_user_id, expected_operations)
    unless folder_id == expected_folder_id && requesting_user_id == expected_user_id && operations == expected_operations
      raise StalePreview, "This preview does not belong to this folder, user, or operation."
    end
  end
end
