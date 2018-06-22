require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :controller, solr: true do 
  render_views
  before(:each) do
    Source.destroy_all
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  describe "GET index" do
    it "read sources index" do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  describe "CREATE" do
    FactoryBot.create(:person) 
    FactoryBot.create(:institution) 
    FactoryBot.create(:standard_title) 
    FactoryBot.create(:standard_term) 
    it "creates record" do
      expect { post :create, :params => FactoryBot.build(:manuscript_source).attributes.except("wf_audit", "wf_stage") }.to change(Source, :count).by(1)
    end
  end

end
