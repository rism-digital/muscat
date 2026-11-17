class BulkMarcPreviewCleanupJob < ApplicationJob
  queue_as :default

  def perform
    deleted = BulkMarcEditDraft.cleanup!
    Rails.logger.info("Bulk MARC preview cleanup: deleted #{deleted} drafts")
    deleted
  end
end
