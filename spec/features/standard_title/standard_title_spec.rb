require 'rails_helper'

RSpec.describe "StandardTitle", :type => :feature, :js => true do 
  describe "Edit"
  let(:user) { FactoryGirl.create(:editor)  }
  before do
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end
  
  it "Standard title title field should not be readonly" do
    existent_title = FactoryGirl.create(:standard_title)
    visit edit_admin_standard_title_path(existent_title)
    expect(page).to have_no_css("#standard_title_title[disabled]") 
  end
  #This will fail also if the field is disabeled
  it "Editors should be able to change standard title authority" do
    existent_title = FactoryGirl.create(:standard_title)
    new_title = "new title"
    visit edit_admin_standard_title_path(existent_title)
    fill_in('standard_title_title', :with => new_title)
    #page.save_screenshot('public/pg.png', :full => true)
    expect(find('#standard_title_title').value).to be == new_title
  end


end

