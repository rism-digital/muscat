require 'rails_helper'
model = :manuscript_source
#changeable_ar_attribute = :wf_stage
RSpec.describe Admin::SourcesController, type: :controller do
  let!(:resource) { create model  }
  let(:user) { create :admin   }
  render_views
  before(:each) do
    sign_in user
  end

  describe "INDEX" do
    it "get sources index" do
      get :index
      expect(response.status).to eq(200)
    end
  end
end
