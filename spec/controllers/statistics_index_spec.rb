require 'rails_helper'

RSpec.describe Admin::StatisticsController, :type => :controller do 
  render_views
  describe "GET index" do
    let!(:user) { FactoryBot.create(:editor)  }
    let!(:source) {FactoryBot.create(:manuscript_source, wf_owner: user.id)}
    before(:each) do
      sign_in user
  end
    it "read page" do
      get :index
      expect(response.body).to have_css ("div#user-table")
    end
  end
end
