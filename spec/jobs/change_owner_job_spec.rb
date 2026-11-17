require "rails_helper"

RSpec.describe ChangeOwnerJob, type: :job do
  let(:admin) { create(:admin) }
  let(:new_owner) do
    create(:cataloger, id: 50, username: "recipient", email: "recipient@example.org")
  end
  let(:folder) { Folder.create!(name: "Records", folder_type: "Publication", user: admin) }

  def prepare_job(requester_id: admin.id)
    described_class.new(folder.id, Folder, :folder_items, new_owner.id,
      requesting_user_id: requester_id).tap do |job|
      allow(job).to receive(:update_stage)
      allow(job).to receive(:update_progress_max)
      allow(job).to receive(:update_stage_progress)
    end
  end

  it "changes the contents' owners without adding unsupported MARC or changing the folder owner" do
    record = create(:publication, wf_owner: admin.id)
    folder.add_item(record)

    queued_job = Delayed::Job.enqueue(described_class.new(
      folder.id, Folder, :folder_items, new_owner.id, requesting_user_id: admin.id
    ))
    Delayed::Job.find(queued_job.id).invoke_job

    expect(record.reload.wf_owner).to eq(new_owner.id)
    expect(record.marc_source).not_to include("=667")
    expect(folder.reload.wf_owner).to eq(admin.id)
  end

  it "retains MARC ownership history for models supporting 667" do
    folder.update!(folder_type: "Work")
    record = create(:work, wf_owner: admin.id)
    folder.add_item(record)

    prepare_job.perform

    expect(record.reload.wf_owner).to eq(new_owner.id)
    expect(record.marc_source).to include("Original cataloger:", "Owner change", "to: #{new_owner.name}")
  end

  it "fails closed when a folder job has no requesting admin" do
    expect { prepare_job(requester_id: nil).perform }.to raise_error(CanCan::AccessDenied)
  end

  it "rechecks the requesting admin's current role after enqueueing" do
    job = prepare_job
    admin.roles.clear

    expect { job.perform }.to raise_error(CanCan::AccessDenied)
  end

  it "rejects a disabled requesting admin" do
    job = prepare_job
    admin.update!(disabled: true)

    expect { job.perform }.to raise_error(CanCan::AccessDenied)
  end

  it "rejects an editor as the requester for a folder job" do
    editor = create(:editor, id: 51, username: "editor", email: "editor@example.org")
    expect { prepare_job(requester_id: editor.id).perform }.to raise_error(CanCan::AccessDenied)
  end

  it "does not follow folder joins pointing to a different model or deleted record" do
    record = create(:publication, wf_owner: admin.id)
    FolderItem.create!(folder: folder, item_type: "Source", item_id: record.id)
    FolderItem.create!(folder: folder, item_type: "Publication", item_id: 999999999)

    prepare_job.perform

    expect(record.reload.wf_owner).to eq(admin.id)
  end

  it "preserves the existing publication job signature and referring works behavior" do
    publication = create(:publication, wf_owner: new_owner.id)
    work = build(:work, wf_owner: admin.id)
    allow(Publication).to receive(:find).with(publication.id).and_return(publication)
    allow(publication).to receive(:referring_works).and_return([work])
    expect(work).to receive(:save!)
    job = described_class.new(publication.id, Publication, :referring_works, new_owner.id)
    allow(job).to receive(:update_stage)
    allow(job).to receive(:update_progress_max)
    allow(job).to receive(:update_stage_progress)

    job.perform

    expect(work.wf_owner).to eq(new_owner.id)
  end
end
