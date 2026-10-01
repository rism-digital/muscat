require "rails_helper"

RSpec.describe User, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let(:admin) do
    create(:admin, password: "AdministratorPass123", password_confirmation: "AdministratorPass123")
  end
  let(:attributes) do
    {
      username: "invitee",
      name: "Invited Cataloguer",
      email: "invitee@example.org"
    }
  end

  describe "#access_role?" do
    it "accepts a primary Muscat role" do
      user = build(:user, roles: [build(:role, name: "cataloger")])

      expect(user).to be_access_role
    end

    it "rejects a supplementary role without a primary role" do
      user = build(:user, roles: [build(:role, name: "person_restricted")])

      expect(user).not_to be_access_role
    end
  end

  it "keeps invitations valid for 15 days" do
    expect(Devise.invite_for).to eq(15.days)
  end

  it "does not apply password complexity rules to the internal invitation password" do
    allow(User).to receive(:random_password).and_return("internal-token-without-digits")

    user = User.invite!(attributes, admin)

    expect(user.errors).to be_empty
    expect(user).to be_persisted
    expect(user).to be_invited_to_sign_up
  end

  it "lets the invited user choose the initial password" do
    user = User.invite!(attributes, admin)
    raw_token = user.raw_invitation_token
    delivery = instance_double(ActionMailer::MessageDelivery, deliver_now: true)
    allow(UserActivationNotification).to receive(:notify).with(user).and_return(delivery)

    accepted_user = User.accept_invitation!(
      invitation_token: raw_token,
      password: "CataloguerPass123",
      password_confirmation: "CataloguerPass123"
    )

    expect(accepted_user.errors).to be_empty
    expect(accepted_user.invitation_accepted_at).to be_present
    expect(accepted_user).not_to be_invited_to_sign_up
    expect(accepted_user.valid_password?("CataloguerPass123")).to be(true)
    expect(delivery).to have_received(:deliver_now)
  end

  it "rejects an invitation after 15 days" do
    user = User.invite!(attributes, admin)
    raw_token = user.raw_invitation_token

    travel 15.days + 1.second do
      accepted_user = User.accept_invitation!(
        invitation_token: raw_token,
        password: "CataloguerPass123",
        password_confirmation: "CataloguerPass123"
      )

      expect(accepted_user.errors[:invitation_token]).to be_present
    end
  end
end
