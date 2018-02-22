require 'rails_helper'
RSpec.describe Admin::SourcesController, :type => :feature, :js => :true do 

  describe "Editors"
  let!(:user) { FactoryBot.create(:editor)  }
  let!(:institution) { FactoryBot.create(:institution) }
  let!(:foreign_institution) { FactoryBot.create(:foreign_institution) }
  let!(:standard_title) { FactoryBot.create(:standard_title) }
  let!(:standard_term) { FactoryBot.create(:standard_term) }
  before do
    Capybara.page.current_window.resize_to(1024, 8000)
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
    visit new_admin_source_path(new_type: "002_source")
    open_all_fields
    set_field("240$0", standard_title.id)
    set_field("650$0", standard_term.id)
    set_field("852$c", "MS2777")
    set_field("245$a", "without any title")
    set_field("240$m", "orch")
    set_field("260$c", "1756")
    set_field("260$a", "Bremen")
    set_field("594$b", "pf")
    set_field("594$c", "1")
    set_field("383$b", "123")
  end

  it "can create source from library" do
    set_field("852$x", institution.id)
    find(:xpath, "//a[@data-action='exit']").click
    sleep 3
    save_screenshot('/tmp/scr1.png', :full => true)
    error = first("div[class='flash flash_error']", visible: false)
    expect(error).to be_nil
  end
  
  it "can create source from foreign library" do
    set_field("852$x", foreign_institution.id)
    find(:xpath, "//a[@data-action='exit']").click
    sleep 3
    save_screenshot('/tmp/scr1.png', :full => true)
    error = first("div[class='flash flash_error']", visible: false)
    expect(error).to be_nil
  end
end
