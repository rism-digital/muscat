require 'rails_helper'

RSpec.describe Admin::SourcesController, :type => :controller do 
  render_views
  let!(:edition) { create :edition }
  let(:user) { FactoryBot.create(:admin)  }
  before do
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
  end
 
  describe "Edition" do
    context "with having a master exemplar" do
      it {
        visit edit_admin_source_path(edition)
        expect(page).to have_css("[data-tag='588']")
        #element = page.find("[data-tag='535'] [data-subfield='a'")"]")
      }
    end
  end

end
