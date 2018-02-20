require 'rails_helper'
RSpec.describe Admin::SourcesController, :type => :feature, :js => :true do 

  describe "Editors"
  let(:user) { FactoryBot.create(:editor)  }
  #let!(:source) { FactoryBot.create(:manuscript_source)  }
  before do
    Capybara.page.current_window.resize_to(1024, 768)
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
  end

  it "can create source from library" do
    #TODO this is a dummy test for saving new records
    FactoryBot.create(:manuscript_source) 
    visit edit_admin_source_path(Source.last.id)
    first(:xpath, "//input[@data-tag='240' and @data-subfield='m']", visible: false).set("pf")
    find(:xpath, "//a[@data-action='exit']").click
    sleep 1
    save_screenshot('/tmp/scr1.png', :full => true)
    expect(1).to eq(2)
  end
end

