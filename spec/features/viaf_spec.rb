require 'rails_helper'

RSpec.describe "VIAF", :type => :feature, :js => true do 
  describe "Viaf form" do
    let(:user) { FactoryBot.create(:cataloger)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
    it "Cataloger should be have person viaf interface interoperable" do
      visit new_admin_person_path
      page.find("#viaf-sidebar").click
      fill_in 'viaf_input', with: 'debussy'
      click_button('viaf_button')
      expect(page).to have_content('Debussy, Emma 1862-1934', wait: 10)
    end
  end
end
