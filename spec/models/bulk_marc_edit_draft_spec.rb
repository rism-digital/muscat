require "rails_helper"

RSpec.describe BulkMarcEditDraft do
  let(:admin) { create(:admin) }
  let(:folder) { Folder.create!(name: "Preview", folder_type: "Publication", user: admin) }
  let(:record) { create(:publication, wf_owner: admin.id) }
  let(:operation) { { action: "add", tag: "500", subfield: "a", target: "new", value: "Preview note" } }

  def prepare(**options)
    folder.add_item(record)
    described_class.prepare(folder, admin, [operation], **options)
  end

  it "previews independent MARC without saving records, versions, or jobs" do
    folder.add_item(record)
    before = record.reload.marc_source
    counts = [PaperTrail::Version.count, Delayed::Job.count]
    draft, rows = prepare

    expect(rows.first[:status]).to eq(:changed)
    expect(rows.first[:after]).to include("Preview note")
    expect(rows.first[:before]).not_to include("Preview note")
    expect(record.reload.marc_source).to eq(before)
    expect([PaperTrail::Version.count, Delayed::Job.count]).to eq(counts)
    expect(draft.sample_snapshot.first["id"]).to eq(record.id)
  end

  it "uses a bounded sample size and stable record ordering" do
    draft, rows = prepare(sample_size: 101)
    expect(draft.sample_size).to eq(10)
    expect(rows.map { |row| row[:id] }).to eq([record.id])
    expect(prepare(sample_size: 100).first.sample_size).to eq(100)
  end

  it "previews the first ten IDs and expands the sample independently of the job's target count" do
    12.times.reverse_each do |index|
      id = 2000 + index
      item = create(:publication, id: id, wf_owner: admin.id,
        marc_source: attributes_for(:publication)[:marc_source].sub("1536", id.to_s))
      folder.add_item(item)
    end
    draft, rows = described_class.prepare(folder, admin, [operation])
    expect(draft.target_count).to eq(12)
    expect(rows.map { |row| row[:id] }).to eq((2000..2009).to_a)
    draft, rows = described_class.prepare(folder, admin, [operation], sample_size: 100)
    expect(draft.target_count).to eq(12)
    expect(rows.length).to eq(12)
  end

  it "rejects expired previews" do
    draft, = prepare
    draft.update!(expires_at: 1.minute.ago)
    expect { draft.enqueue!(folder, admin) }.to raise_error(described_class::StalePreview, /expired/)
    expect(draft.reload.confirmed_at).to be_nil
  end

  it "rejects previews after a sampled record changes" do
    draft, = prepare
    record.update_column(:marc_source, record.marc_source + "=500  #\#$aConcurrent edit\n")
    expect { draft.enqueue!(folder, admin) }.to raise_error(described_class::StalePreview, /changed/)
  end

  it "rejects previews after membership or configuration changes" do
    draft, = prepare
    folder.folder_items.delete_all
    expect { draft.enqueue!(folder, admin) }.to raise_error(described_class::StalePreview)
    draft, = prepare
    draft.update!(configuration_digest: "different")
    expect { draft.enqueue!(folder, admin) }.to raise_error(described_class::StalePreview)
  end

  it "runs a confirmed draft once and applies the approved operation" do
    draft, = prepare
    job = draft.enqueue!(folder, admin)
    Delayed::Job.find(job.id).invoke_job
    expect(record.reload.marc_source).to include("Preview note")
    expect(described_class.exists?(draft.id)).to be(false)
    expect { Delayed::Job.find(job.id).invoke_job }.to raise_error(described_class::StalePreview)
  end

  it "checks for changes while the job was waiting in the queue" do
    draft, = prepare
    job = draft.enqueue!(folder, admin)
    record.update_column(:marc_source, record.marc_source + "=500  #\#$aConcurrent edit\n")
    expect { Delayed::Job.find(job.id).invoke_job }.to raise_error(described_class::StalePreview)
    expect(record.reload.marc_source).not_to include("Preview note")
  end

  it "will not execute a draft with a different operation or without confirmation" do
    draft, = prepare
    expect { draft.start!(folder, admin, draft.operations) }.to raise_error(described_class::StalePreview)
    draft.enqueue!(folder, admin)
    expect { draft.start!(folder, admin, []) }.to raise_error(described_class::StalePreview)
  end

  it "reports unchanged and conflicting records without writing anything" do
    operation.merge!(action: "change", old_value: "not present")
    _, rows = prepare
    expect(rows.first[:status]).to eq(:unchanged)
    operation.merge!(action: "add", tag: "210", target: "new")
    _, rows = prepare
    expect(rows.first[:status]).to eq(:invalid)
    expect(rows.first[:error]).to include("not repeatable")
  end

  it "keeps the old draft when the replacement is invalid and protects confirmed drafts" do
    draft, = prepare
    expect do
      draft.replace_with!(folder, admin, [operation.merge(tag: "invalid")])
    end.to raise_error(BulkMarcEditor::InvalidOperation)
    expect(described_class.exists?(draft.id)).to be(true)
    expect(described_class.count).to eq(1)
    draft.enqueue!(folder, admin)
    expect do
      draft.replace_with!(folder, admin, [operation])
    end.to raise_error(described_class::StalePreview, /already been confirmed/)
    expect(described_class.exists?(draft.id)).to be(true)
  end
end
