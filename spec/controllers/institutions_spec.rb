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

  context "GET index" do
    before do
      results = Kaminari.paginate_array([institution]).page(1).per(10)
      allow(Institution).to receive(:search_as_ransack).and_return([results, []])
      allow(Source).to receive(:get_terms).with("368a_sms").and_return([])
    end

    it "shows workgroup and distinct user counts to admins" do
      sign_in create(:admin, workgroups: [])

      get :index

      row = Nokogiri::HTML(response.body).at_css("#institution_#{institution.id}")
      expect(row).to have_css("td.col-workgroups-count", text: "1")
      expect(row).to have_css("td.col-workgroup-users-count", text: "1")
    end

    it "shows the count columns to editors" do
      sign_in create(:editor, id: 4, workgroups: [])

      get :index

      expect(response.body).to have_css("th.col-workgroups-count", text: "GRPs")
      expect(response.body).to have_css("th.col-workgroup-users-count", text: "Users")
    end

    it "hides the count columns from catalogers" do
      sign_in create(:cataloger, id: 5, workgroups: [])

      get :index

      expect(response.body).not_to have_css("th.col-workgroups-count")
      expect(response.body).not_to have_css("th.col-workgroup-users-count")
    end
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
