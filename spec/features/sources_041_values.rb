require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :feature, :js => :true do 

  let(:user) { FactoryBot.create(:cataloger)  }
  before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
  end
  
  describe "sources edit form" do
    it "should contain value 'West Frisian'" do
      visit "/admin/sources/new?new_type=002_source"
      expect(page.find("select[data-tag='041'][data-subfield='a']")).to have_css("option", text: 'West Frisian')
    end
  end

end
