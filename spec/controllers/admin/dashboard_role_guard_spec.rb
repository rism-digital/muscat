require "rails_helper"

RSpec.describe Admin::DashboardController, type: :controller do
  render_views

  let(:roleless_user) do
    create(
      :user,
      roles: [],
      password: "RolelessPassword123",
      password_confirmation: "RolelessPassword123"
    )
  end

  before do
    sign_in roleless_user
  end

  it "renders a stable forbidden page instead of redirecting" do
    get :index

    expect(response).to have_http_status(:forbidden)
    expect(response).not_to be_redirect
    expect(response.body).to include("No role has been assigned to your account")
    expect(response.body).to include(roleless_user.email)
    expect(response.body).to include("Sign out")
  end
end
