require 'rails_helper'

RSpec.describe "Abilities", :type => :feature, :js => true do 
  describe "Person editor" do
    let(:user) { FactoryBot.create(:person_editor)  }
    let(:person) { FactoryBot.create(:person)  }
    before do
      visit user_session_path
      fill_in :user_login, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
    it "Person editor should have all fields writeable with person" do
      visit edit_admin_person_path(person)
      input_field = page.find(:xpath, "//input[@data-tag='100' and @data-subfield='a']")
      expect(input_field["disabled"]).to eq(nil) 
    end
  end
end
