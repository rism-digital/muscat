require 'rails_helper'
RSpec.describe Admin::SourcesController, type: :controller, solr: true do
  FactoryBot.create(:person)
  let(:user) { create :admin   }
  render_views
  before(:each) do
    Sunspot.remove_all!(Source)
    sign_in user
  end

  describe "creating record" do
   it "should change the solr index result" do
      initial_size = Source.solr_search { with("240a_filter", "Jesu meine Freude")  }.total
      FactoryBot.create(:manuscript_source)
      #post :create, :params => {model => FactoryBot.attributes_for(model)}
      # Indexing needs some time
      #sleep 5
      Sunspot.index[Source]
      Sunspot.commit
      after_create_size = Source.solr_search { with("240a_filter", "Jesu meine Freude")  }.total
      expect(after_create_size).to eq(initial_size + 1)
    end
  end
  
  describe "updating record" do
    let!(:standard_title) { create :standard_title, title: "xxx"   }
    it "should change the solr index result" do
      #binding.pry
      #StandardTitle.destroy_all
      #Sunspot.index[StandardTitle]
      #Sunspot.commit
      #TODO imrpove solr test
      #Sunspot.index[StandardTitle]
      initial_size = Source.solr_search { with("240a_filter", "Jesu meine Freude")  }.total
      FactoryBot.create(:manuscript_source)
      resource = Source.where(std_title: "Jesu meine Freude").take
      marc = resource.marc.dup
      marc.each_by_tag("240") do |tag|
        zero_tag = tag.fetch_first_by_tag("0")
        if zero_tag && zero_tag.content
          StandardTitle.find(zero_tag.content).referring_sources.delete(resource)
        end
        zero_tag.destroy_yourself rescue nil
        tag.add_at(MarcNode.new("source", "0", standard_title.id, nil), 0)
        tag.foreign_object = standard_title
        a_tag = tag.fetch_first_by_tag("a")
        a_tag.content = standard_title.title
        tag.sort_alphabetically
      end
      resource.save
      #binding.pry
      Sunspot.index[Source]
      Sunspot.commit
      #sleep 10
      after_create_size = Source.solr_search { with("240a_filter", "xxx")  }.total
      expect(after_create_size).to eq(initial_size + 1)
      #expect(1).to eq(1)
    end
  end

  describe "Edition fingerprint" do
   it "fulltext search should contain record with fingerprint in 026e" do
      initial_size = Source.solr_search {fulltext 'FINGERPRINT12345'}.total
      FactoryBot.create(:edition)
      Sunspot.index[Source]
      Sunspot.commit
      after_create_size = Source.solr_search { fulltext 'FINGERPRINT12345' }.total
      expect(after_create_size).to eq(initial_size + 1)
    end
  end
end
