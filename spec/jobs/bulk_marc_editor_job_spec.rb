require "rails_helper"

RSpec.describe BulkMarcEditorJob, type: :job do
  let(:admin) { create(:admin) }
  let(:folder) { Folder.create!(name: "Bulk MARC", folder_type: "Publication", user: admin) }
  let(:operation) { { "action" => "add", "tag" => "500", "subfield" => "a", "target" => "new", "value" => "Bulk note" } }

  it "persists the job, edits records, records the actor, and reports completion" do
    record = create(:publication, wf_owner: admin.id)
    folder.add_item(record)
    job = Delayed::Job.enqueue(described_class.new(folder.id, [operation], admin.id))

    Delayed::Job.find(job.id).invoke_job

    expect(record.reload.marc_source).to include("Bulk note")
    expect(record.versions.last.whodunnit).to eq(admin.name)
    expect(record.versions.last.event).to include("Bulk MARC edit")
    expect(job.reload.progress_current).to eq(1)
    expect(job.progress_stage).to include("1 changed, 0 unchanged, 0 failed")
  end

  it "fails closed if the requester no longer has admin access" do
    job = described_class.new(folder.id, [operation], admin.id)
    admin.roles.clear
    expect { job.perform }.to raise_error(CanCan::AccessDenied)
  end

  it "rejects a disabled admin or missing requester" do
    admin.update!(disabled: true)
    expect { described_class.new(folder.id, [operation], admin.id).perform }.to raise_error(CanCan::AccessDenied)
    expect { described_class.new(folder.id, [operation], nil).perform }.to raise_error(CanCan::AccessDenied)
  end

  it "rolls back all operations on a conflicting record and continues with the others" do
    first = create(:publication, wf_owner: admin.id)
    second = create(:publication, id: 1537, wf_owner: admin.id,
      marc_source: attributes_for(:publication)[:marc_source].sub("1536", "1537"))
    second.marc["210"].each(&:destroy_yourself)
    second.save!
    folder.add_item(first)
    folder.add_item(second)
    conflict = { "action" => "add", "tag" => "210", "subfield" => "a", "target" => "new", "value" => "New short name" }
    job = Delayed::Job.enqueue(described_class.new(folder.id, [operation, conflict], admin.id))

    expect { Delayed::Job.find(job.id).invoke_job }.to raise_error(described_class::PartialFailure)

    expect(first.reload.marc_source).not_to include("Bulk note")
    expect(second.reload.marc_source).to include("Bulk note", "New short name")
    expect(job.reload.progress_stage).to include("1 changed, 0 unchanged, 1 failed")
  end

  it "deletes the draft after a partial failure while retaining failed-job diagnostics" do
    record = create(:publication, wf_owner: admin.id)
    folder.add_item(record)
    conflict = { action: "add", tag: "210", subfield: "a", target: "new", value: "Conflict" }
    draft, = BulkMarcEditDraft.prepare(folder, admin, [operation, conflict], modification_reason: "Correct cataloguing data")
    job = draft.enqueue!(folder, admin)

    expect(Delayed::Worker.new(quiet: true).run(job)).to be(false)

    expect(BulkMarcEditDraft.exists?(draft.id)).to be(false)
    expect(job.reload.failed_at).to be_present
    expect(job.last_error).to include("1 failed", "not repeatable")
    expect(record.reload.marc_source).not_to include("Bulk note")
  end

  it "deletes the draft when execution fails before processing any records" do
    draft, = BulkMarcEditDraft.prepare(folder, admin, [operation], modification_reason: "Correct cataloguing data")
    job = draft.enqueue!(folder, admin)
    admin.roles.clear

    expect { Delayed::Job.find(job.id).invoke_job }.to raise_error(CanCan::AccessDenied)
    expect(BulkMarcEditDraft.exists?(draft.id)).to be(false)
  end

  it "does not execute or remove a different job's preview" do
    draft, = BulkMarcEditDraft.prepare(folder, admin, [operation], modification_reason: "Correct cataloguing data")
    actual_job = draft.enqueue!(folder, admin)
    duplicate = Delayed::Job.enqueue(described_class.new(folder.id, [operation], admin.id, preview_draft_id: draft.id))

    expect { Delayed::Job.find(duplicate.id).invoke_job }.to raise_error(BulkMarcEditDraft::StalePreview, /different job/)
    expect(draft.reload.delayed_job_id).to eq(actual_job.id)
    expect(draft.started_at).to be_nil
    Delayed::Job.find(actual_job.id).invoke_job
    expect(BulkMarcEditDraft.exists?(draft.id)).to be(false)
  end

  it "uses the reviewed reason as the PaperTrail event and leaves unchanged records alone" do
    first = create(:publication, wf_owner: admin.id)
    second = create(:publication, id: 1537, wf_owner: admin.id,
      marc_source: attributes_for(:publication)[:marc_source].sub("1536", "1537").gsub("NBA", "Other"))
    folder.add_item(first)
    folder.add_item(second)
    versions_before = second.versions.count
    edit = { action: "change", tag: "210", subfield: "a", old_value: "NBA", value: "Updated" }
    draft, = BulkMarcEditDraft.prepare(folder, admin, [edit], modification_reason: "Correct the catalogue abbreviation")
    job = draft.enqueue!(folder, admin)

    Delayed::Job.find(job.id).invoke_job

    expect(first.reload.versions.last.event).to eq("Correct the catalogue abbreviation")
    expect(first.short_name).to eq("Updated")
    expect(second.reload.versions.count).to eq(versions_before)
    expect(second.short_name).to eq("Other")
  end

  it "rejects a reason changed after confirmation before saving any records" do
    record = create(:publication, wf_owner: admin.id)
    folder.add_item(record)
    draft, = BulkMarcEditDraft.prepare(folder, admin, [operation], modification_reason: "Reviewed reason")
    job = draft.enqueue!(folder, admin)
    draft.update!(modification_reason: "Changed after confirmation")

    expect { Delayed::Job.find(job.id).invoke_job }.to raise_error(BulkMarcEditDraft::StalePreview, /reason differs/)
    expect(record.reload.marc_source).not_to include("Bulk note")
  end

  it "preserves execution of confirmed jobs queued before modification reasons existed" do
    record = create(:publication, wf_owner: admin.id)
    folder.add_item(record)
    draft, = BulkMarcEditDraft.prepare(folder, admin, [operation], modification_reason: "Temporary fixture reason")
    job = draft.enqueue!(folder, admin)
    draft.update_column(:modification_reason, nil)
    payload = job.payload_object
    payload.remove_instance_variable(:@modification_reason)
    job.payload_object = payload
    job.save!

    Delayed::Job.find(job.id).invoke_job

    expect(record.reload.marc_source).to include("Bulk note")
    expect(record.versions.last.event).to eq("Bulk MARC edit (folder #{folder.id})")
  end
end
