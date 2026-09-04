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

RSpec.describe Sru::Query do
  describe "request validation" do
    it "treats a request without an operation as explain without searching Solr" do
      expect(Sunspot).not_to receive(:search)

      query = Sru::Query.new("sources")

      expect(query.operation).to eq("explain")
      expect(query.error_code).to be_nil
      expect(query.result).to be_nil
    end

    it "rejects non-positive and malformed maximumRecords values" do
      ["0", "-1", "10records", ["10"]].each do |value|
        query = Sru::Query.new(
          "sources",
          { query: "*", operation: "searchRetrieve", maximumRecords: value }
        )

        expect(query.error_code[:code]).to eq(6)
        expect(query.result).to be_nil
      end
    end

    it "enforces the configured normal record limit" do
      query = Sru::Query.new(
        "sources",
        { query: "*", operation: "searchRetrieve", maximumRecords: "101" }
      )

      expect(query.error_code[:code]).to eq(60)
      expect(query.error_code[:message]).to include("100 records")
    end

    it "allows the server-controlled export limit without x-action" do
      query = Sru::Query.new(
        "sources",
        { query: "*", operation: "searchRetrieve", maximumRecords: 2_001 },
        maximum_records_limit: 2_000
      )

      expect(query.error_code[:code]).to eq(60)
      expect(query.error_code[:message]).to include("2000 records")
    end

    it "rejects invalid operations, deep offsets, and oversized queries" do
      invalid_operation = Sru::Query.new("sources", { operation: "destroy", query: "*" })
      deep_offset = Sru::Query.new(
        "sources",
        {
          operation: "searchRetrieve",
          query: "*",
          startRecord: (Sru::Query::MAXIMUM_START_RECORD + 1).to_s
        }
      )
      oversized_query = Sru::Query.new(
        "sources",
        {
          operation: "searchRetrieve",
          query: "a" * (Sru::Query::MAXIMUM_QUERY_BYTES + 1)
        }
      )

      expect(invalid_operation.error_code[:code]).to eq(6)
      expect(deep_offset.error_code[:code]).to eq(61)
      expect(oversized_query.error_code[:code]).to eq(10)
    end

    it "uses an explicit model allowlist" do
      query = Sru::Query.new("application_records", { query: "*", operation: "searchRetrieve" })

      expect(query.error_code[:code]).to eq(235)
      expect(query.model).to be_nil
    end
  end

end
