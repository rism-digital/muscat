require 'rails_helper'
RSpec.describe Admin::SourcesController, :type => :feature, :js => :true do 

  describe "Editors"
  let!(:user) { FactoryBot.create(:cataloger)  }
  let!(:institution) { FactoryBot.create(:institution) }
  let!(:foreign_institution) { FactoryBot.create(:foreign_institution) }
  let!(:person) { FactoryBot.create(:person) }
  let!(:standard_title) { FactoryBot.create(:standard_title) }
  let!(:standard_term) { FactoryBot.create(:standard_term) }
  before do
    Capybara.page.current_window.resize_to(1024, 8000)
    visit user_session_path
    fill_in :user_email, :with => user.email
    fill_in :user_password, :with => user.password
    click_button('Login')
    visit new_admin_source_path(new_type: "002_source")
    #open_all_fields
    set_field("240$0", standard_title.id)
    set_field("650$0", standard_term.id)
    set_field("852$c", "MS2777")
    set_field("245$a", "€_=$$%%<<>○><&&///?%=without any title")
    set_field("240$m", "orch")
    set_field("260$c", "1756")
    set_field("260$a", "Bremen")
    set_field("594$b", "pf")
    set_field("594$c", "1")
    #set_field("383$b", "123")
  end

  it "can create source from library", gui: true do
    set_field("100$0", person.id)
    set_field("852$x", institution.id)
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    #save_screenshot('/tmp/scr1.png', :full => true)
    error = first("div[class='flash flash_error']", visible: false)
    expect(error).to be_nil
  end
  
  it "cannot create source from foreign library", gui: true do
    set_field("100$0", person.id)
    set_field("852$x", foreign_institution.id)
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    error = first("div[class='flash flash_error']", visible: false)
    expect(error.text).to match(/Your are not allowed to create sources with siglum/)
  end
  
  it "should be warning for incipit higher than 200", gui: true  do
    set_field("100$0", person.id)
    set_field("852$x", institution.id)
    set_field("031$a", "211")
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    warning = first("div[class='flash flash_warning']", visible: false)
    expect(warning.text).to match(/value '211' is greater than 200/)
  end
 
  it "warning should be triggered only one time", gui: true  do
    set_field("100$0", person.id)
    set_field("852$x", institution.id)
    set_field("031$a", "211")
    find(:xpath, "//a[@data-action='exit']").click
    #save_screenshot('/tmp/scr1.png', :full => true)
    sleep 2
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    #save_screenshot('/tmp/scr2.png', :full => true)
    warning = first("div[class='flash flash_warning']", visible: false)
    expect(warning).to be_nil
  end
   
  it "errors should be in a endless loop", gui: true  do
    set_field("100$0", person.id)
    set_field("852$x", foreign_institution.id)
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    error = first("div[class='flash flash_error']", visible: false)
    expect(error.text).to match(/Your are not allowed to create sources with siglum/)
  end
  
  it "cannot create source without composer", gui: true  do
    set_field("852$x", institution.id)
    find(:xpath, "//a[@data-action='exit']").click
    sleep 2
    error = first("div[class='flash flash_error']", visible: false)
    expect(error.text).to match(/is mandatory for this template/)
  end
 
  it "error should have higher priority than warning", gui: true do
    skip "is in development" do
      set_field("100$0", person.id)
      set_field("852$x", institution.id)
      set_field("031$a", "211")
      find(:xpath, "//a[@data-action='exit']").click
      sleep 2
      #warning = first("div[class='flash flash_warning']", visible: false)
      remove_field("100$0")
      remove_field("100$a")
      find(:xpath, "//a[@data-action='exit']").click

      save_screenshot('/tmp/scr1.png', :full => true)
      expect(1).to be 2
    end
    #expect(warning.text).to match(/value '211' is greater than 200/)
  end
 
end
