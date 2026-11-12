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

  it "returns only progress data to a signed-in user" do
    sign_in create(:admin, workgroups: [], password: password, password_confirmation: password)

    get :show, params: { job_id: job.id }, format: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to eq(
      "progress_stage" => "Saving <record>",
      "progress_current" => 2,
      "progress_max" => 4,
      "percentage" => 50.0,
      "status" => "queued"
    )
  end

  it "allows signed-in non-admin users to poll progress" do
    sign_in create(:editor, workgroups: [], password: password, password_confirmation: password)

    get :show, params: { job_id: job.id }, format: :json

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).not_to have_key("handler")
    expect(response.parsed_body).not_to have_key("last_error")
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

    expect(response.parsed_body).to eq(
      "status" => "complete",
      "progress_stage" => nil,
      "progress_current" => nil,
      "progress_max" => nil,
      "percentage" => 100
    )
  end
end
