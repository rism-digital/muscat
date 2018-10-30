require 'rails_helper'
RSpec.describe Admin::SourcesController, type: :controller do
  let!(:foreign_source) { create :foreign_manuscript_source }
  let!(:source) { create :manuscript_source }
  let(:user) { create :cataloger   }
  render_views
  before(:each) do
    sign_in user
  end

  context "when user creates a record from foreign library" do
    it "there should be a validation error notice" do
      marc_params = FactoryBot.attributes_for(:foreign_marc_source)[:marc] 
      post :marc_editor_validate, :params => {marc: marc_params, current_user: user.id} 
      hash = JSON.parse(response.body)
      expect(hash["status"]).to match /insufficient rights/
    end
  end

  context "when user creates a record from his library" do
    it "there should be no validation error notice" do
      marc_params = FactoryBot.attributes_for(:marc_source)[:marc] 
      post :marc_editor_validate, :params => {marc: marc_params, current_user: user.id} 
      hash = JSON.parse(response.body)
      expect(hash["status"]).to match /\[200\]/
    end
  end

  context "when 856$a is given" do 
    it "then 856$x should be required" do
      skip "to be implemented"
    end
  end

end
