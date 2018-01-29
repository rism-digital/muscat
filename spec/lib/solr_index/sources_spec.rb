require 'rails_helper'
model = :source
title = "XXXXX"
RSpec.describe Admin::SourcesController, type: :controller do
  let!(:resource) { create model  }
  let!(:standard_title) { create :standard_title, title: title  }
  let(:user) { create :admin   }
  render_views
  before(:each) do
    sign_in user
  end

  describe "creating record" do
    it "should change the solr index result" do
      title_previous = "Il trionfo di Camilla regina de Volsci"
      initial_size = Source.solr_search { with("240a_filter", title_previous)  }.total
      post :create, :params => {model => FactoryBot.attributes_for(model)}
      after_create_size = Source.solr_search { with("240a_filter", title_previous)  }.total
      expect(after_create_size).to eq(initial_size + 1)
    end
  end
  
  describe "updating record" do
    it "should change the solr index result" do
      initial_size = Source.solr_search { with("240a_filter", title)  }.total
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
      resource.index!
      after_create_size = Source.solr_search { with("240a_filter", title)  }.total
      expect(after_create_size).to eq(initial_size + 1)
    end
  end



end
