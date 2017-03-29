require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :controller do 
  render_views
  describe "GET index" do
  before(:each) do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end
    it "read sources index" do
      get :index
      # To have access to the controller directly use e.g.:
      #request.env['action_controller.instance'].instance_variable_get(:@results)
      expect(response.body).to have_css ("#titlebar_left")
      
    end
  end
end
