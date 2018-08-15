require 'rails_helper'

RSpec.describe Admin::StandardTermsController, :type => :controller do 
  render_views
  let!(:standard_term) { create :standard_term }
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
      patch :update, params: { :id => standard_term.id, :standard_term => { :term => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
