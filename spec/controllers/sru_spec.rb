require 'rails_helper'

RSpec.describe SruController, :type => :controller, solr: true do
  render_views
  
  context "with explaining MaximumRecords" do
    it do
      get "service", params: {:query => 'Bach', :operation => "searchRetrieve", :maximumRecords => 200}
      doc = Nokogiri::XML(response.body)
      diag = "http://www.loc.gov/zing/srw/diagnostic/"
      max = doc.xpath("//diag:message", "diag" => diag).first.content
      expect(max).to match(/MaximumRecords is limited/)
    end
  end

  context "with explaining default url" do
    it do
      get "service"
      doc = Nokogiri::XML(response.body)
      namespace="http://explain.z3950.org/dtd/2.0/" 
      hostinfo = doc.xpath("//ns:serverInfo/ns:host", "ns" => namespace).first.content
      expect(hostinfo).to eq "muscat.rism.info"
    end
  end

  context "with an in-memory export" do
    let(:record) do
      double(
        "record",
        id: 1,
        name: "=unsafe title",
        date_from: "1700",
        lib_siglum: "D-B",
        shelf_mark: "Mus. 1",
        created_at: Time.zone.parse("2024-01-01"),
        updated_at: Time.zone.parse("2024-01-02"),
        marc: marc
      )
    end
    let(:marc) { double("marc") }
    let(:result) { double("result", total: 1, hits: [double("hit", result: record)]) }
    let(:query) do
      double(
        "query",
        result: result,
        error_code: nil,
        schema: "html",
        query: "title=R&B</zs:query><injected/>",
        maximumRecords: 2_000
      )
    end

    before do
      allow(Sru::Query).to receive(:new).and_return(query)
    end

    it "generates CSV without touching a shared export file" do
      expect(CSV).not_to receive(:open)
      expect(IO).not_to receive(:write)

      get "service", params: {
        operation: "searchRetrieve",
        query: "*",
        recordSchema: "html",
        "x-action" => "csv"
      }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/csv")
      expect(response.body).to include("'=unsafe title")
    end

    it "builds well-formed XML and escapes the echoed query" do
      allow(marc).to receive(:to_xml).and_return(
        '<marc:record xmlns:marc="http://www.loc.gov/MARC21/slim"><marc:controlfield tag="001">1</marc:controlfield></marc:record>'
      )

      get "service", params: {
        operation: "searchRetrieve",
        query: "*",
        recordSchema: "html",
        "x-action" => "download"
      }

      document = Nokogiri::XML(response.body) { |config| config.strict }
      namespaces = { "zs" => "http://www.loc.gov/zing/srw/" }
      expect(response.media_type).to eq("application/xml")
      expect(document.xpath("//zs:record", namespaces).length).to eq(1)
      expect(document.at_xpath("//zs:query", namespaces).text).to eq(query.query)
      expect(document.xpath("//injected")).to be_empty
    end
  end

end
