require "rails_helper"

RSpec.describe Admin::InstitutionsController, type: :controller do
  render_views

  let!(:institution) { create(:institution) }
  let!(:workgroup) do
    create(:workgroup, name: "Referenced workgroup", libpatterns: nil, institutions: [institution])
  end
  let!(:member) do
    create(:user, id: 3, name: "Workgroup member", workgroups: [workgroup])
  end

  context "GET show" do
    it "shows linked workgroups and their users to admins" do
      sign_in create(:admin)

      get :show, params: { id: institution.id }

      expect(response.body).to include(I18n.t(:workgroups_with_institution_permissions))
      expect(response.body).to include(I18n.t(:users_with_institution_permissions))
      expect(response.body).to have_css(
        %(a[href="#{admin_workgroup_path(workgroup)}"]),
        text: "View"
      )
      expect(response.body).to have_css(
        %(a[href="#{admin_user_path(member)}"]),
        text: "View"
      )
    end

    it "shows linked workgroups and their users to editors" do
      sign_in create(:editor, id: 4)

      get :show, params: { id: institution.id }

      expect(response.body).to have_css(%(a[href="#{admin_workgroup_path(workgroup)}"]))
      expect(response.body).to have_css(%(a[href="#{admin_user_path(member)}"]))
    end

    it "hides linked workgroups and their users from guests" do
      sign_in create(:guest, id: 5)

      get :show, params: { id: institution.id }

      expect(response.body).not_to have_css(%(a[href="#{admin_workgroup_path(workgroup)}"]))
      expect(response.body).not_to have_css(%(a[href="#{admin_user_path(member)}"]))
    end

    it "hides linked workgroups and their users from catalogers" do
      sign_in create(:cataloger, id: 6)

      get :show, params: { id: institution.id }

      expect(response.body).not_to have_css(%(a[href="#{admin_workgroup_path(workgroup)}"]))
      expect(response.body).not_to have_css(%(a[href="#{admin_user_path(member)}"]))
    end
  end
end
