#require 'rails_helper'
#
#RSpec.describe Admin::SourcesController, :type => :feature, :js => :true do 
#
#  describe "Editors"
#  let(:user) { FactoryBot.create(:editor)  }
#  let(:source) { FactoryBot.create(:source)  }
#  let!(:work) { FactoryBot.create(:work)  }
#  before do
#    visit user_session_path
#    fill_in :user_email, :with => user.email
#    fill_in :user_password, :with => user.password
#    click_button('Login')
#  end
#
#  it "can link works to sources" do
#    work.index!
#    visit edit_admin_source_path(source.id)
#    find("div[data-tag='930'] a").click
#    find(:css, "input[id='930a']").set(work.title)
#    #page.execute_script("$('#930a').trigger('focus')")
#    #page.execute_script("$('#930a').trigger('keydown')")
#    #find(:css, "input[id='930a']").click
#    puts find(:css, "input[id='930a']").value
#    save_screenshot('/tmp/scr1.jpg', :full => true)
#    #find("[data-action='exit']").click
#    #save_screenshot('/tmp/scr2.jpg', :full => true)
#    #visit "admin/sources/#{source.id}.xml"
#    expect(1).to eq(2)
#  end
#end
#
