require "rails_helper"

[SaveItemsJob, ReindexItemsJob].each do |job_class|
  RSpec.describe job_class, type: :job do
    %w[delete destroy! user].each do |relation|
      it "rejects queued #{relation} before loading or invoking the parent" do
        expect(Source).not_to receive(:find)
        job = described_class.new(123, Source, relation)
        expect { job.perform }.to raise_error(ArgumentError, "Invalid collection relation")
      end
    end

    it "processes a valid empty collection" do
      actor = create(:admin)
      folder = Folder.create!(name: "Job relations", folder_type: "Source", user: actor)
      job = described_class.new(folder.id, Folder, :folder_items)
      delayed_job = Delayed::Job.create!(handler: "security regression")
      allow(Sunspot).to receive(:commit)
      job.before(delayed_job)

      expect { job.perform }.not_to raise_error
      expect(delayed_job.reload.progress_max).to eq(0)
      expect(folder.reload).to be_persisted
    end
  end
end
