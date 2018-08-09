require 'rails_helper'

RSpec.describe Admin::StandardTermsController, :type => :controller do 
  render_views
  let!(:standard_term) { create :standard_term }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  describe "GET index" do
    it "read standard_term index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  describe "correct redirect" do
    it "incorrect input should redirect to root path" do
      patch :update, params: { :id => standard_term.id, :standard_term => { :term => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
