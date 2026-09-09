require "rails_helper"

RSpec.describe Admin::SourcesController, type: :controller do
  let(:user) { create(:admin) }

  before do
    sign_in user
  end

  describe "GET new" do
    it "builds the proper child from a supported parent" do
      parent = Source.create!(
        id: 12_345,
        record_type: MarcSource::RECORD_TYPES.fetch(:collection),
        marc_source: <<~MARC
          =001  000012345
          =100  1#$aParent Composer$jAttributed name
          =650  07$aMasses
          =852  ##$aCH-Bu$cShelf 42
        MARC
      )

      get :new, params: { derived_from_source_id: parent.id }

      expect(response).to have_http_status(:ok)
      child = assigns(:source)
      expect(child.get_record_type).to eq(:source)
      expect(child.source_id).to be_nil
      expect(child.marc.to_marc).to include("=773  18$w12345")
      expect(child.marc.to_marc).to include("=852  ##$aCH-Bu$cShelf 42")
    end

    it "rejects a parent type which cannot derive a child" do
      parent = Source.create!(
        id: 23_456,
        record_type: MarcSource::RECORD_TYPES.fetch(:source),
        marc_source: "=001  000023456\n"
      )

      get :new, params: { derived_from_source_id: parent.id }

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:error]).to eq(I18n.t(:invalid_derived_child_source))
    end

    it "rejects a missing parent" do
      get :new, params: { derived_from_source_id: 999_999_999 }

      expect(response).to redirect_to(admin_root_path)
      expect(flash[:error]).to eq(I18n.t(:invalid_derived_child_source))
    end
  end
end
