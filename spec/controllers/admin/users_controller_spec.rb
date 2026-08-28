require "rails_helper"

RSpec.describe Admin::UsersController, type: :controller do
  let(:admin) do
    create(:admin, password: "AdministratorPass123", password_confirmation: "AdministratorPass123")
  end
  let(:cataloger_role) { create(:cataloger_role) }
  let(:user_attributes) do
    {
      username: "invitee",
      name: "Invited Cataloguer",
      email: "invitee@example.org",
      password: "AdministratorPassword123",
      password_confirmation: "AdministratorPassword123",
      role_ids: [cataloger_role.id],
      workgroup_ids: []
    }
  end

  before do
    sign_in admin
    ActionMailer::Base.deliveries.clear
  end

  describe "GET index" do
    it "links workgroups to their show pages with a sigla tooltip" do
      workgroup = admin.workgroups.first

      get :index

      link = Nokogiri::HTML(response.body).at_css(
        %(a[href="#{admin_workgroup_path(workgroup)}"])
      )

      expect(link.text).to eq(workgroup.name)
      expect(link["title"]).to eq(workgroup.show_libs(max: 10))
      expect(response.body).to include(I18n.t(:workgroup_sigla_hint))
    end

    it "uses a localized tooltip when the workgroup has no sigla" do
      workgroup = admin.workgroups.first
      workgroup.institutions.clear

      get :index

      link = Nokogiri::HTML(response.body).at_css(
        %(a[href="#{admin_workgroup_path(workgroup)}"])
      )

      expect(link["title"]).to eq(I18n.t(:workgroup_no_sigla))
    end
  end

  describe "POST create" do
    it "creates a pending user and emails an invitation" do
      I18n.with_locale(:de) do
        expect do
          post :create, params: { creation_mode: "invite", user: user_attributes }
        end.to change(User, :count).by(1)
          .and change { ActionMailer::Base.deliveries.count }.by(1)
      end

      user = User.find_by!(email: "invitee@example.org")

      expect(user).to be_invited_to_sign_up
      expect(user.roles).to include(cataloger_role)
      expect(user.valid_password?("AdministratorPassword123")).to be_falsey
      expect(ActionMailer::Base.deliveries.last.attachments["rism-logo.png"]).to be_inline
      expect(ActionMailer::Base.deliveries.last.html_part.body.decoded).to include("Muscat account invitation")
      expect(ActionMailer::Base.deliveries.last.html_part.body.decoded).to include("Choose my password")
      expect(ActionMailer::Base.deliveries.last.subject).to eq("Set up your Muscat account")
      expect(response).to redirect_to(admin_user_path(user))
    end

    it "allows an invitation to be created without a password" do
      attributes_without_password = user_attributes.merge(password: "", password_confirmation: "")

      expect do
        post :create, params: { creation_mode: "invite", user: attributes_without_password }
      end.to change(User, :count).by(1)
        .and change { ActionMailer::Base.deliveries.count }.by(1)

      expect(User.find_by!(email: "invitee@example.org")).to be_invited_to_sign_up
    end

    it "creates an immediately active user when a password is supplied" do
      original_delivery_count = ActionMailer::Base.deliveries.count

      expect do
        post :create, params: { creation_mode: "password", user: user_attributes }
      end.to change(User, :count).by(1)

      user = User.find_by!(email: "invitee@example.org")

      expect(ActionMailer::Base.deliveries.count).to eq(original_delivery_count)
      expect(user).not_to be_invited_to_sign_up
      expect(user.invitation_sent_at).to be_nil
      expect(user.valid_password?("AdministratorPassword123")).to be(true)
      expect(response).to redirect_to(admin_user_path(user))
    end

    it "requires a password for immediate activation" do
      attributes_without_password = user_attributes.merge(password: "", password_confirmation: "")

      expect do
        post :create, params: { creation_mode: "password", user: attributes_without_password }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:user).errors[:password]).to be_present
    end

    it "does not create a user without a role" do
      attributes_without_role = user_attributes.merge(role_ids: [])

      expect do
        post :create, params: { creation_mode: "invite", user: attributes_without_role }
      end.not_to change(User, :count)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:user).errors[:roles]).to include("Please select an access role (admin, editor, cataloger, or guest).")
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end

  describe "POST resend_invitation" do
    it "replaces the pending invitation token and sends another email" do
      user = User.invite!(user_attributes.except(:password, :password_confirmation), admin)
      previous_token = user.invitation_token

      expect do
        post :resend_invitation, params: { id: user.id }
      end.to change { ActionMailer::Base.deliveries.count }.by(1)

      expect(user.reload.invitation_token).not_to eq(previous_token)
      expect(response).to redirect_to(admin_user_path(user))
    end
  end
end
