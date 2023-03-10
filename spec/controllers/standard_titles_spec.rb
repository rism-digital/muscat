require 'rails_helper'

RSpec.describe Admin::StandardTitlesController, :type => :controller do 
  render_views
  let!(:standard_title) { create :standard_title }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  context "GET index" do
    it "read standard_title index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  context "correct redirect" do
    it do
      patch :update, params: { :id => standard_title.id, :standard_title => { :title => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

end
