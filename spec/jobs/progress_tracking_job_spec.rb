require "rails_helper"

RSpec.describe Muscat::ProgressTrackingJob, type: :job do
  it "records progress through the Delayed Job callbacks" do
    delayed_job = Delayed::Job.create!(handler: "job payload")
    progress_job = described_class.new(progress_max: 5)

    progress_job.before(delayed_job)
    progress_job.update_stage_progress("Working", step: 2)

    expect(delayed_job.reload.attributes).to include(
      "progress_max" => 5,
      "progress_current" => 2,
      "progress_stage" => "Working"
    )

    progress_job.error(delayed_job, StandardError.new("Failed"))
    expect(delayed_job.reload.progress_stage).to eq("Failed")
  end
end
