require 'rails_helper'

RSpec.describe "Abilities", :type => :feature, :js => true do 
  describe "Cataloger with restricted person access" do
    let(:user) { FactoryGirl.create(:person_restricted)  }
    let(:person) { FactoryGirl.create(:person)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
      visit edit_admin_person_path(person)
    end
    it "Catalogers with people ability should not have all fields writeable" do
      collapsables = page.find_all(:xpath, "//div[@class='tag_group']//a[@title='Add tag']")
      collapsables.each do |c| 
        c.click 
      end
      save_screenshot('/tmp/screenshot.jpg', :full => true)
      tags = (EditorConfiguration.get_default_layout Person.first).options_config
      unrestricted_fields = Hash.new([])
      tags.each do |tag|
        if CollectionHelper::ConfigHash.new(tag).contains?("unrestricted")
          tag[1]["layout"]["fields"].each do |subfield|
            if CollectionHelper::ConfigHash.new(subfield).contains?("unrestricted")
              unrestricted_fields[tag[0]] += [subfield[0]]
            end
          end
        end
      end
      input_fields = page.find_all(:xpath, "//input[@data-tag]|//select[@data-tag]")
      input_fields.each do |field|
        if unrestricted_fields[field["data-tag"]] && unrestricted_fields[field["data-tag"]].include?(field["data-subfield"])
           expect(field["disabled"]).to eq(false) 
        else
           expect(field["disabled"]).to eq(true)
        end
      end
    end
  end 
end
