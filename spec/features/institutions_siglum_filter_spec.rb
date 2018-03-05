require 'rails_helper'

RSpec.describe "Institutions siglum filter", :type => :feature, :js => true do 
  describe "Siglum filter on index page" do
    let(:user) { FactoryBot.create(:cataloger)  }
    before do
      FactoryBot.create(:institution)
      FactoryBot.create(:source)
      Sunspot.index![Source]
      visit user_session_path
      fill_in :user_email, :with => user.email
      fill_in :user_password, :with => user.password
      click_button('Login')
    end
    it "truncated search with '*' (eg. 'D-*') should return matched libraries" do
      visit admin_institutions_path
      fill_in 'q_110g_facet_contains', with: 'D-*'
      find('input[name="commit"]').click
      expect(page.all("#index_table_institutions tbody tr").size).to eq 1
    end
    it "truncated search without truncation '*' (eg. 'D-') should return zero" do
      visit admin_institutions_path
      fill_in 'q_110g_facet_contains', with: 'D-'
      find('input[name="commit"]').click
      expect(page.all("#index_table_institutions tbody tr").size).to eq 0
    end

  end
end
