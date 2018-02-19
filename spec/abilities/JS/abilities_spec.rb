require 'rails_helper'

RSpec.describe "Abilities", :type => :feature, :js => true do 
  
  describe "Person_editor" do
    let(:user) { FactoryBot.create(:person_editor)  }
    before do
      FactoryBot.create(:person)
      Sunspot.index![Person]
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
    let(:user) { FactoryBot.create(:editor)  }
    before do
      FactoryBot.create(:person)
      Sunspot.index![Person]
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
      visit admin_people_path
    end
    it "Editors should not have the 'edit' link in the index table" do
      expect(page).to have_no_css("a.edit_link") 
    end
    it "Editors should have the 'create' action" do
      expect(page).to have_xpath("//a[@class='muscat_icon_link muscat_icon_link_new']") 
    end
  end

  describe "Cataloger" do
    let(:user) { FactoryBot.create(:editor)  }
    before do
      FactoryBot.create(:person)
      Sunspot.index![Person]
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
      visit admin_people_path
    end
    it "Catalogers should not have the 'edit' link in the index table" do
      expect(page).to have_no_css("a.edit_link") 
    end
    it "Catalogers should have the 'create' action" do
      expect(page).to have_xpath("//a[@class='muscat_icon_link muscat_icon_link_new']") 
    end
  end

  describe "Guest" do
    let(:user) { FactoryBot.create(:guest)  }
    before do
      FactoryBot.create(:person)
      Sunspot.index![Person]
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
      visit admin_people_path
    end
    it "Guests should not have the 'edit' link in the index table" do
      expect(page).to have_no_css("a.edit_link") 
    end
    it "Guests should not have the 'create' action" do
      expect(page).to have_no_xpath("//a[@class='muscat_icon_link muscat_icon_link_new']") 
    end
  end




end

