require 'rails_helper'


RSpec.describe "JS check dependencies", :type => :feature, :js => true do 
  describe "institution" do
    let(:user) { FactoryBot.create(:editor)  }
    let!(:source) { FactoryBot.create(:manuscript_source)  }
    before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
    it "destroying institution with dependencies should raise error notice" do
      i = Institution.last
      visit admin_institution_path(i)
      find(:css, ".muscat_icon_link.muscat_icon_link_delete").click
      page.driver.browser.switch_to.alert.accept
      alert = page.find(:css, ".flash.flash_error")
      expect(alert.text).to eq("The Institution could not be deleted because it is used by 1 referring sources and 1 places")
    end
    
    context "Destroying unlinked feast should not raise error notice" do
      let!(:feast) { FactoryBot.create(:liturgical_feast)  }
      it do
        i = LiturgicalFeast.last
        visit admin_liturgical_feast_path(i)
        find(:css, ".muscat_icon_link.muscat_icon_link_delete").click
        page.driver.browser.switch_to.alert.accept
        alert = page.find(:css, ".flash.flash_notice")
        expect(alert.text).to eq("Liturgical festivals was successfully destroyed.")
      end
    end

  end
end
