require 'rails_helper'

RSpec.describe Admin::CatalogController, type: :feature do

  describe "whith anonymous navigation disabled" do
    it "redirects to sign in" do
      RISM::ANONYMOUS_NAVIGATION= false
      visit search_catalog_path
      expect(page.current_path).to eq("/admin/login")
    end
  end

  describe "whith anonymous navigation enabled" do
    before do
      RISM::ANONYMOUS_NAVIGATION= true
    end

    after do
      RISM::ANONYMOUS_NAVIGATION= false
    end

    it "renders the catalog" do
      visit search_catalog_path

      expect(page).to have_content("The simple search mode is the easiest way to start a search.")
    end
  end

end
