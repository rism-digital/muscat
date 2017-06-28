require 'rails_helper'

RSpec.describe "Editor_Abilities", :type => :feature, :js => true do 
  describe "Person_editor" do
    let(:user) { FactoryGirl.create(:person_editor)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
  
    it "Person_editor should have the 'edit' link in the index table" do
      visit admin_people_path
      expect(page).to have_css("a.edit_link") 
    end
  end

  describe "Editor" do
    let(:user) { FactoryGirl.create(:editor)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
  
    it "Editors should not have the 'edit' link in the index table" do
      visit admin_people_path
      expect(page).to have_no_css("a.edit_link") 
    end
  end


end

