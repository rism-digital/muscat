require 'rails_helper'

RSpec.describe Admin::PlacesController, :type => :controller do 
  render_views
  let!(:place) { create :place }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  describe "GET index" do
    it "read places index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  describe "correct redirect" do
    it "incorrect input should redirect to root path" do
      patch :update, params: { :id => place.id, :place => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
