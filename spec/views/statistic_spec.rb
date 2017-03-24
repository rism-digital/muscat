require 'capybara/rails'
require 'rails_helper'
#include Devise::TestHelpers
RSpec.feature "home page", type: :feature do
  #@admin = FactoryGirl.create :admin
  #sign_in nil
  #dummy = create(:user)
    @admin = FactoryGirl.create :user
  before :each do    
    sign_in @admin
  end
  describe "navigation" do
    it " shows me menu" do
      visit "/admin/statistic"
      binding.pry
      expect(page.find('#page_title')).to have_content("Statistic") # page find search for css path
    end
  end
end



#describe "statistic page should show 12 month chart" do
#  it "this page should include month june" do
#    pending
#  end
#end

