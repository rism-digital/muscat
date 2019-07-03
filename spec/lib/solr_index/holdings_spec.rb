require 'rails_helper'

RSpec.describe Admin::SourcesController, type: :controller, as: :json, solr: true do
  let(:user) { create :admin   }
  render_views
  before(:each) do
    Sunspot.remove_all!(Source)
    sign_in user
  end

  describe "CREATE" do
    it "creating sources" do
      initial_size = Source.solr_search { with("240a_filter", "Jesu meine Freude")  }.total

      FactoryBot.create(:standard_title) 
      FactoryBot.create(:standard_term)
      edition = FactoryBot.build(:edition_json).to_h

      post :marc_editor_save, params: edition rescue nil
      Sunspot.index[Source]
      Sunspot.commit
      after_create_size = Source.solr_search { with("240a_filter", "Jesu meine Freude")  }.total
      expect(after_create_size).to eq(initial_size + 1)
    end
  end
end


