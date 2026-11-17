class BulkMarcEditorJob < Muscat::ProgressTrackingJob
  class PartialFailure < StandardError; end

  def initialize(folder_id, operations, requesting_user_id, preview_draft_id: nil)
    super()
    @folder_id = folder_id
    @operations = operations
    @requesting_user_id = requesting_user_id
    @preview_draft_id = preview_draft_id
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
    if @preview_draft_id
      draft = BulkMarcEditDraft.find_by(id: @preview_draft_id)
      raise BulkMarcEditDraft::StalePreview, "This preview is no longer available." unless draft

      draft.start!(folder, requester, operations, job_id: @job&.id)
    end
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

  # Delayed Job invokes this after success or failure, including failures before
  # record editing starts. Only delete the draft belonging to this job; a forged
  # or duplicate payload must not remove a different job's active preview.
  def after(job)
    BulkMarcEditDraft.where(id: @preview_draft_id, delayed_job_id: job.id).delete_all if @preview_draft_id
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
