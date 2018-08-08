require 'rails_helper'
RSpec.describe Admin::GuidelinesController, type: :feature do
  let(:user) { create :admin   }
  before(:each) do
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end

  describe "guidelines documentation" do
    it "version number should be equal to muscat version" do
      visit "admin/guidelines"
      muscat_version = page.find("#footer").text.split("/")[1].split("-")[0]
      guidelines_version = page.find(".tabpanel/h3").text.split(" ")[1]
      expect(guidelines_version).to eq(muscat_version)
    end
  end

end
