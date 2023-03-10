require 'rails_helper'

RSpec.describe Admin::PlacesController, :type => :controller do 
  render_views
  let!(:place) { create :place }
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
      patch :update, params: { :id => place.id, :place => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
