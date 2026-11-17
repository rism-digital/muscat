class BulkMarcEditorJob < Muscat::ProgressTrackingJob
  class PartialFailure < StandardError; end

  def initialize(folder_id, operations, requesting_user_id)
    super()
    @folder_id = folder_id
    @operations = operations
    @requesting_user_id = requesting_user_id
  end

  def enqueue(job)
    job.update!(parent_id: @folder_id, parent_type: "folder")
  end

  def perform
    # The controller supplies the actor from the authenticated session.
    # Recheck current access in case it changed while the job was queued.
    requester = User.find_by(id: @requesting_user_id)
    unless requester && !requester.disabled? && requester.has_role?(:admin)
      raise CanCan::AccessDenied, "Only administrators can bulk edit MARC records"
    end

    folder = Folder.find(@folder_id)
    editor = BulkMarcEditor.new(folder.folder_model)
    operations = editor.validate_operations(@operations)
    ids = folder.folder_items.where(item_type: folder.folder_type).select(:item_id)
    records = folder.folder_model.where(id: ids)
    update_progress_max(records.count)
    changed = unchanged = failed = 0
    failures = []

    PaperTrail.request(whodunnit: requester.name) do
      records.find_each do |record|
        begin
          record.class.transaction(requires_new: true) do
            record.lock!
            if editor.apply(record, operations)
              record.paper_trail_event = "Bulk MARC edit (folder #{folder.id})" if record.respond_to?(:paper_trail_event=)
              record.save!
              changed += 1
            else
              unchanged += 1
            end
          end
        rescue BulkMarcEditor::InvalidOperation, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => error
          failed += 1
          failures << "#{record.class}/#{record.id}: #{error.message}" if failures.length < 10
          Rails.logger.error("Bulk MARC edit folder=#{folder.id} record=#{record.class}/#{record.id}: #{error.message}")
        end
        update_stage_progress("Bulk MARC edit: #{changed} changed, #{unchanged} unchanged, #{failed} failed")
      end
    end
    summary = "Bulk MARC edit complete: #{changed} changed, #{unchanged} unchanged, #{failed} failed"
    update_stage(summary)
    # Retain partial failures in the job monitor for review; do not retry adds.
    raise PartialFailure, "#{summary}. #{failures.join('; ')}" if failed.positive?
  end

  def max_attempts
    1
  end

  def destroy_failed_jobs?
    false
  end

  def queue_name
    "resave"
  end
end
