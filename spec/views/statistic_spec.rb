require 'rails_helper'
=begin
describe 'Users' do
  fixtures :all
  let(:user) { admin_users(:user)  }
  before { sign_in :user  }

  describe '#index' do
    it 'renders without fail' do
      visit '/admin/usejjrs'
      expect(page).to have_content('exampl')
    end
  end
end
=end


require 'capybara/rails'
#include Devise::TestHelpers
RSpec.feature "home page", type: :feature do
  #@admin = FactoryGirl.create :admin
  #sign_in nil
  #dummy = create(:user)
  #Warden.test_reset!
    describe "navigation", :type => :request do
  user = FactoryGirl.create(:user)
  before do
    sign_in(user, :scope => :user, :run_callbacks => false)
  end



it "bla" do

      visit "/admin/login"
      binding.pry
       fill_in('admin_user_email', :with =>  "admin@example.com")
        fill_in('admin_user_password', :with => "password")
         click_button('Login')
          page.must_have_content("Signed in successfull")
    end
end
end
=begin
      before :each do   
    user = FactoryGirl.create(:user)
    login_as(user, :scope => :user, :run_callbacks => false)
  end

    it " shows me menu" do
      visit "/admin/login"
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
=end
