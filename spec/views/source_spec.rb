require 'rails_helper'

RSpec.describe "Sources",  :type => :feature, js: true do
  let(:user) { create :admin   }
  before(:each) do
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end

  describe "Index page" do
    it "should contain the sidebar panel" do
      visit admin_sources_path
      expect(page).to have_css("#sidebar")
    end
    it "should current set to sources" do
      visit admin_sources_path
      expect(page.title).to match(Regexp.new(page.find(".current").text))
    end
  end
end


