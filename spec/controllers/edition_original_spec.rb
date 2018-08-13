require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :controller do 
  render_views
  let!(:edition) { create :edition }
  let(:user) { FactoryBot.create(:admin)  }
  before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
  end
 
  describe "Edition" do
    it "there should be the possibibility to specify the master holding in 535" do
      visit edit_admin_source_path(edition)
      expect(page).to have_css("[data-tag='535']")
      #element = page.find("[data-tag='535'] [data-subfield='a'")"]")
    end
  end

end
