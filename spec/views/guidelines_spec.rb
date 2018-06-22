require 'rails_helper'

RSpec.describe "Guidelines",  :type => :feature, js: true do
  let(:user) { create :admin   }
  before(:each) do
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end

  describe "Index page" do
    it "should have current set to pagetitle" do
      visit admin_guidelines_path
      expect(page.title).to match(/#{Regexp.escape(page.find(".current").text)}/i)
    end
  end
end


