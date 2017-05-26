require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :controller do 
  render_views
  before(:each) do
    @user = FactoryGirl.create(:admin)
    sign_in @user
  end

  describe "GET index" do
    it "read sources index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  describe "CREATE" do
    it "creates record" do
      expect { post :create, :source => FactoryGirl.attributes_for(:source) }.to change(Source, :count).by(1)
    end
  end

end
