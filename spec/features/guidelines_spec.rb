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
      muscat_version = page.find("#footer").text.split("/")[1].gsub(/[^0-9]/, "")[0..1]
      guidelines_version= page.find_all(:xpath, ".//h3").first.text.split(" ")[1].gsub(/[^0-9]/, "")[0..1]
      expect(guidelines_version).to eq(muscat_version)
    end
  end

end
