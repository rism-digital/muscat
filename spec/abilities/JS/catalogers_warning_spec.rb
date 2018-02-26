require 'rails_helper'
RSpec.describe Admin::SourcesController, :type => :feature, :js => :true do 

  describe "catalogers"
  let!(:user) { FactoryBot.create(:cataloger)  }
  let!(:source) { FactoryBot.create(:manuscript_source) }
  before do
    Capybara.page.current_window.resize_to(1024, 8000)
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
    visit edit_admin_source_path(source.id)
  end

  it "editing record should raise warnings too", gui: true do
    set_field("031$a", "211")
    set_field("240$m", "coro")
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    warning = first("div[class='flash flash_warning']", visible: false)
    expect(warning.text).to match(/value '211' is greater than 200/)
  end
 end
