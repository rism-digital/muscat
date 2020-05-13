RSpec.describe Sru::Query, solr: true do
  before(:each) do
    FactoryBot.create(:manuscript_source)
    Sunspot.index![Source]
  end
  context "Simple fulltext search with astersik" do
    it do
      query = Sru::Query.new("sources", {:query => "*", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end

  context "Simple fulltext search result size" do
    it do
      query = Sru::Query.new("sources", {:query => "Bach", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  context "Simple index search with base result size" do
    it do
      query = Sru::Query.new("sources", {:query => "dc.creator=\"Bach, Johann Sebastian\"", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  context "Simple index search without base result size" do
    it do
      query = Sru::Query.new("sources", {:query => "creator=\"Bach, Johann Sebastian\"", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  context "ID search without base result size" do
    it do
      query = Sru::Query.new("sources", {:query => "id=#{Source.last.id}", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  context "Combined index search with AND result size" do
    it do
      query = Sru::Query.new("sources", {:query => "name=\"Bach, Johann Sebastian\" and rism.siglum=D-B", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  #TODO for 2 different sources
  context "Combined index and fulltext search with OR result size" do
    it do
      query = Sru::Query.new("sources", {:query => "watermark=\"a) W in überkröntem Schild - b) leer (oder nicht erkennbar)\" or \"Freude\"", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  context "Fulltext search with unphrased term and two terms and logical AND result size" do
    it "returns > 120" do
      query = Sru::Query.new("sources", {:query => "Bach, Johann Sebastian and Freude", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end
  context "Search with keyword in phrase result size" do
    it "returns = 1" do
      query = Sru::Query.new("sources", {:query => "\"Wahrscheinlich identisch\" and Freude", :operation => "searchRetrieve"})
      expect(query.result.total).to be == 1
    end
  end

end
