require 'rails_helper'

RSpec.describe Admin::PlacesController, :type => :controller do 
  render_views
  let!(:place) { create :place }
  before(:each) do
    @user = FactoryBot.create(:admin)
    sign_in @user
  end

  context "GET index", :web do
    it do
      get :index
      expect(response.body).to have_css ("#titlebar_left")
    end
  end

  context "redirect_to back" do
    it do
      patch :update, params: { :id => place.id, :place => { :name => nil  } }
      expect(response).to redirect_to(root_path)
    end
  end

  context "GET show_by_tgn" do
    it "redirects to the matching place" do
      place.update_column(:tgn_id, "7006660")

      get :show_by_tgn, params: { tgn_id: "7006660" }

      expect(response).to redirect_to(admin_place_path(place))
    end

    it "redirects to the places list when no place matches" do
      get :show_by_tgn, params: { tgn_id: "7006660" }

      expect(response).to redirect_to(admin_places_path)
      expect(flash[:error]).to eq(
        "#{I18n.t(:error_not_found)} (TGN 7006660)",
      )
    end
  end

end
