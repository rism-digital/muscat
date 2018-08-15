require 'rails_helper'
RSpec.describe Admin::SourcesController, type: :controller do
  let!(:person) { create :person }
  let(:user) { create :cataloger   }
  render_views
  before(:each) do
    sign_in user
  end

  context "when user creats a record from foreign library" do
    it "there should be a validation error notice" do
      skip "to be implemented"
    end
  end

  context "when 856$a is given" do 
    it "then 856$x should be required" do
      skip "to be implemented"
    end

  end

end
