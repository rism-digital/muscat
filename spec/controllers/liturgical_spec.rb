require 'rails_helper'

RSpec.describe Admin::LiturgicalFeastsController, :type => :controller do 
  render_views
  let!(:feast) { create :liturgical_feast }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  describe "GET index" do
    it "read liturgicalfeast index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  describe "correct redirect" do
    it "incorrect input should redirect to root path" do
      f = LiturgicalFeast.last
      patch :update, params: { :id => f.id, :liturgical_feast => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
