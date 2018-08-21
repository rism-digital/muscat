require 'rails_helper'

RSpec.describe Admin::WorkgroupsController, :type => :controller do 
  render_views
  let!(:workgroup) { create :workgroup }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  context "GET index" do
    it do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  context "redirect_to back" do
    it do
      patch :update, params: { :id => workgroup.id, :workgroup => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
