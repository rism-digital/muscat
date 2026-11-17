class BulkMarcEditDraft < ApplicationRecord
  class StalePreview < StandardError; end

  SAMPLE_SIZES = [10, 25, 50, 100].freeze
  serialize :operations, coder: JSON
  serialize :sample_snapshot, coder: JSON

  # Every delete retains its state predicate, so confirmation racing a sweep
  # cannot turn an abandoned preview into a deleted active job draft.
  def self.cleanup!
    pending = where(confirmed_at: nil)
    abandoned = pending.where("expires_at <= ?", Time.current)
      .or(pending.where.not(folder_id: Folder.select(:id)))
      .or(pending.where.not(requesting_user_id: User.select(:id)))
    active_job_ids = Delayed::Job.where(failed_at: nil).select(:id)
    orphaned = where.not(confirmed_at: nil)
      .where(delayed_job_id: nil)
      .or(where.not(confirmed_at: nil).where.not(delayed_job_id: active_job_ids))
    abandoned.delete_all + orphaned.delete_all
  end

  def self.prepare(folder, user, operations, sample_size: 10)
    BulkMarc::Preview.prepare(folder, user, operations, sample_size: sample_size)
  end

  def ensure_fresh!(folder)
    unless BulkMarc::Preview.fresh?(self, folder)
      raise StalePreview, "Records or configuration changed since this preview. Refresh the preview before applying."
    end
  rescue BulkMarc::InvalidOperation
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
      job = Delayed::Job.enqueue(BulkMarcEditorJob.new(folder.id, operations, user.id, preview_draft_id: id))
      update!(delayed_job_id: job.id)
      job
    end
  rescue ActiveRecord::RecordNotFound
    raise StalePreview, "This preview is no longer available; generate a new one."
  end

  # Only remove the old preview after a replacement was successfully generated.
  # Hold its lock to prevent an older browser tab confirming it concurrently.
  def replace_with!(folder, user, new_operations, sample_size: 10)
    with_lock do
      ensure_context!(folder.id, user.id, operations)
      raise StalePreview, "This preview has already been confirmed." if confirmed_at

      replacement = self.class.prepare(folder, user, new_operations, sample_size: sample_size)
      destroy!
      replacement
    end
  rescue ActiveRecord::RecordNotFound
    raise StalePreview, "This preview is no longer available; generate a new one."
  end

  def start!(folder, user, job_operations, job_id: nil)
    with_lock do
      ensure_context!(folder.id, user.id, job_operations)
      raise StalePreview, "This preview has not been confirmed, or has already started." unless confirmed_at && !started_at
      raise StalePreview, "This preview belongs to a different job." unless delayed_job_id == job_id

      ensure_fresh!(folder)
      update!(started_at: Time.current)
    end
  rescue ActiveRecord::RecordNotFound
    raise StalePreview, "This preview is no longer available."
  end

  private

  def ensure_context!(expected_folder_id, expected_user_id, expected_operations)
    unless folder_id == expected_folder_id && requesting_user_id == expected_user_id && operations == expected_operations
      raise StalePreview, "This preview does not belong to this folder, user, or operation."
    end
  end
end
