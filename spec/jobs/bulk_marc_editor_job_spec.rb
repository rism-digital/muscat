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
end
