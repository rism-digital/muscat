require 'rails_helper'

RSpec.describe "Abilities", :type => :feature, :js => true do 
  describe "Cataloger with restricted person access" do
    let(:user) { FactoryGirl.create(:person_restricted)  }
    let(:person) { FactoryGirl.create(:person)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
    it "Catalogers with people ability should not have all fields writeable" do
      visit edit_admin_person_path(person)
      input_field = page.find(:xpath, "//input[@data-tag='100' and @data-subfield='a']")
      expect(input_field["disabled"]).to eq(true) 
    end
  end
end

=begin
RSpec.describe "Abilities", :type => :feature, :js => true do 
  describe "Cataloger with people abilities" do
    let(:editor) { FactoryGirl.create(:editor)  }
    let(:person) { FactoryGirl.create(:person)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => editor.email
      fill_in :user_password, :with => editor.password
      click_button('Login')
    end
    it "Editors should have all fields writeable" do
      visit edit_admin_person_path(person)
      binding.pry
      input_field = page.find(:xpath, "//input[@data-tag='100' and @data-subfield='a']")
      expect(input_field.readonly?).to eq(false) 
    end
  end
=end


