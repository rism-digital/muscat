require 'rails_helper'

RSpec.describe "Institutions",  :type => :feature, js: true do
  let(:user) { create :admin   }
  before(:each) do
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end

  describe "Institution page" do
    it "should not contain a map" do
      visit "admin/institutions"
      expect(page).to_not have_css("#map")
    end
  end

  describe "BSB page" do
    it "should contain a map" do
      visit "admin/institutions/30000882"
      expect(page).to have_css("#map")
    end
  end
end
