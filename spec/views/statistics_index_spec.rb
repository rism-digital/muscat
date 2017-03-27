require 'rails_helper'

RSpec.describe Admin::StatisticsController, :type => :controller do 
  render_views
  describe "GET index" do
  before(:each) do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end
    it "read page" do
      get :index
      binding.pry
      expect(response.body).to have_css ("div#user-table")
    end
  end
end
