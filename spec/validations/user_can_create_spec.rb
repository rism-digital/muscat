require 'rails_helper'
RSpec.describe Admin::SourcesController, type: :controller do
  let!(:person) { create :person }
  let(:user) { create :admin   }
  render_views
  before(:each) do
    sign_in user
  end

  context "when creating new record from foreign library" do
    it "there should be a validation notice" do
    end
  end

end
