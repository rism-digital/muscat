require "rails_helper"

RSpec.describe ProgressJob::ProgressController, type: :controller do
  let(:password) { "ProgressPass123!" }

  let(:job) do
    Delayed::Job.create!(
      handler: "private job payload",
      progress_stage: "Saving <record>",
      progress_current: 2,
      progress_max: 4,
      last_error: "private backtrace"
    )
  end

  it "returns only progress data to a job manager" do
    sign_in create(:admin, workgroups: [], password: password, password_confirmation: password)

    get :show, params: { job_id: job.id }, format: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "progress_stage" => "Saving <record>",
      "progress_current" => 2,
      "progress_max" => 4,
      "percentage" => 50.0,
      "last_error" => true
    )
  end

  it "does not expose job data to users who cannot manage jobs" do
    sign_in create(:editor, workgroups: [], password: password, password_confirmation: password)

    get :show, params: { job_id: job.id }, format: :json

    expect(response).to have_http_status(:forbidden)
  end

  it "reports zero percent when the maximum is zero" do
    sign_in create(:admin, workgroups: [], password: password, password_confirmation: password)
    job.update_column(:progress_max, 0)

    get :show, params: { job_id: job.id }, format: :json

    expect(response.parsed_body["percentage"]).to eq(0)
  end

  it "keeps the completed-job response expected by the progress bar" do
    sign_in create(:admin, workgroups: [], password: password, password_confirmation: password)

    get :show, params: { job_id: -1 }, format: :json

    expect(response.parsed_body).to eq("none")
  end
end
