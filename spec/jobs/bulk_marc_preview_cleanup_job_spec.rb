require "rails_helper"

RSpec.describe BulkMarcPreviewCleanupJob, type: :job do
  let(:admin) { create(:admin) }
  let(:folder) { Folder.create!(name: "Cleanup", folder_type: "Publication", user: admin) }
  let(:operation) { { action: "add", tag: "500", subfield: "a", target: "new", value: "Note" } }

  def draft
    BulkMarcEditDraft.prepare(folder, admin, [operation]).first
  end

  it "deletes expired unused previews and keeps recent previews" do
    expired = draft
    expired.update!(expires_at: 1.second.ago)
    recent = draft
    expect(described_class.perform_now).to eq(1)
    expect(BulkMarcEditDraft.exists?(expired.id)).to be(false)
    expect(BulkMarcEditDraft.exists?(recent.id)).to be(true)
    expect(described_class.perform_now).to eq(0)
  end

  it "protects expired previews for queued and running jobs" do
    queued, running = draft, draft
    queued.enqueue!(folder, admin)
    job = running.enqueue!(folder, admin)
    job.update!(locked_at: Time.current, locked_by: "worker")
    BulkMarcEditDraft.where(id: [queued.id, running.id]).update_all(expires_at: 2.days.ago)
    expect(described_class.perform_now).to eq(0)
    expect(BulkMarcEditDraft.where(id: [queued.id, running.id]).count).to eq(2)
  end

  it "removes cancelled, deleted, and failed job drafts without deleting diagnostics" do
    cancelled, failed, orphaned = draft, draft, draft
    cancelled.enqueue!(folder, admin).destroy!
    job = failed.enqueue!(folder, admin)
    job.update!(failed_at: Time.current, last_error: "Retain this diagnostic")
    orphaned.update!(confirmed_at: Time.current, started_at: Time.current)
    expect(described_class.perform_now).to eq(3)
    expect(job.reload.last_error).to eq("Retain this diagnostic")
    expect(BulkMarcEditDraft.count).to eq(0)
  end

  it "removes unconfirmed previews whose folder or requesting user no longer exists" do
    missing_folder, missing_user = draft, draft
    missing_folder.update!(folder_id: 999999999)
    missing_user.update!(requesting_user_id: 999999999)
    expect(described_class.perform_now).to eq(2)
  end

  it "links already queued jobs from before the migration so cleanup preserves them" do
    require Rails.root.join("db/migrate/20261117150000_link_bulk_marc_edit_drafts_to_jobs")
    existing = draft
    job = existing.enqueue!(folder, admin)
    existing.update!(delayed_job_id: nil, expires_at: 1.day.ago)
    LinkBulkMarcEditDraftsToJobs.new.send(:link_existing_jobs)
    expect(existing.reload.delayed_job_id).to eq(job.id)
    expect(described_class.perform_now).to eq(0)
  end
end
