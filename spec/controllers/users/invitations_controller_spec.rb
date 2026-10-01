require "rails_helper"

RSpec.describe Users::InvitationsController, type: :controller do
  let(:admin) do
    create(:admin, password: "AdministratorPass123", password_confirmation: "AdministratorPass123")
  end

  before do
    @request.env["devise.mapping"] = Devise.mappings[:user]
  end

  it "signs out an existing user before displaying an invitation" do
    invited_user = User.invite!(
      {
        username: "invitee",
        name: "Invited Cataloguer",
        email: "invitee@example.org"
      },
      admin
    )
    invitation_token = invited_user.raw_invitation_token
    sign_in admin
    session["user_return_to"] = accept_user_invitation_path(invitation_token: invitation_token)

    get :edit, params: { invitation_token: invitation_token }

    expect(response).to have_http_status(:ok)
    expect(controller.current_user).to be_nil
    expect(session["user_return_to"]).to be_nil
  end

  it "does not expose the generic invitation form" do
    get :new

    expect(response).to have_http_status(:not_found)
  end

  it "does not accept invitations outside the administrator user form" do
    post :create, params: { user: { email: "invitee@example.org" } }

    expect(response).to have_http_status(:not_found)
  end
end
