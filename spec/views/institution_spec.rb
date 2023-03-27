require 'rails_helper'

RSpec.describe "Institutions",  :type => :feature, js: true do
  let(:user) { create :admin   }
  before(:each) do
    visit user_session_path
    fill_in :user_login, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end
  describe "BSB page" do
    xit "should contain a map" do
      visit "admin/institutions/30000655"
      expect(page).to have_css("#map")
    end
  end
end
