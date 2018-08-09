require 'rails_helper'

RSpec.describe Admin::WorkgroupsController, :type => :controller do 
  render_views
  let!(:workgroup) { create :workgroup }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  describe "GET index" do
    it "read workgroup index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  describe "correct redirect" do
    it "incorrect input should redirect to root path" do
      patch :update, params: { :id => workgroup.id, :workgroup => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
