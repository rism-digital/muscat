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
    it "should contain a map" do
      visit "admin/institutions"
      expect(page).to have_css("#sidebar")
    end
    it "should contain a sidebar" do
      visit "admin/institutions"
      fill_in 'q_110g_facet_contains', with: 'D-Mbs'
      click_button('Filter') do
        expect(page).to have_css("#sidebar")
        expect(page).to have_css("#map")
      end
    end
  end
end
