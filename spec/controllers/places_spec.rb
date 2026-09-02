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

  context "TGN place preloading" do
    it "loads matching places for unique TGN identifiers in one query" do
      tags = ["7006660", "7006660", "7004333"].map do |id|
        instance_double(MarcNode, tag: "370").tap do |tag|
          allow(tag).to receive(:fetch_first_by_tag).with("2")
            .and_return(instance_double(MarcNode, content: "tgn"))
          allow(tag).to receive(:fetch_first_by_tag).with("u")
            .and_return(instance_double(MarcNode, content: "https://vocab.getty.edu/tgn/#{id}"))
        end
      end
      marc = instance_double(Marc)
      allow(marc).to receive(:each_by_tag).with("370") do |&block|
        tags.each(&block)
      end
      item = instance_double(Place, marc: marc)
      matching_places = [instance_double(Place, tgn_id: "7006660")]

      expect(Place).to receive(:where)
        .with(tgn_id: ["7006660", "7004333"])
        .once
        .and_return(matching_places)

      controller.send(:preload_tgn_places, item)

      places_by_tgn_id = controller.instance_variable_get(:@places_by_tgn_id)
      expect(places_by_tgn_id.keys).to contain_exactly("7006660")
    end
  end

end
