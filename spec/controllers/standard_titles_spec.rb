require 'rails_helper'

RSpec.describe Admin::StandardTitlesController, :type => :controller do 
  render_views
  let!(:standard_title) { create :standard_title }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  context "GET index" do
    it "read standard_title index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  context "correct redirect" do
    it do
      patch :update, params: { :id => standard_title.id, :standard_title => { :title => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

  context "POST merge" do
    it "does not allow a guest to merge records" do
      guest = create(
        :guest,
        id: 54,
        username: "merge-guest",
        email: "merge-guest@example.org"
      )
      target = create(:standard_title, id: 3_905_619, title: "Target")
      sign_out @user
      sign_in guest

      expect_any_instance_of(StandardTitle).not_to receive(:migrate_to_id)

      post :merge, params: { duplicate: standard_title.id, target: target.id }

      expect(response).to have_http_status(:redirect)
    end
  end

end
