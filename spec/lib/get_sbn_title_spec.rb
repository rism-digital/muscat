require "rspec"
require_relative "../../lib/get_sbn_title"

RSpec.describe GetSBNTitle do
  it "fetches and decodes the first work title" do
    response = Net::HTTPOK.new("1.1", "200", "OK")
    response.body = '{"data":{"results":[{"title":"Bach &amp; Handel"}]}}'
    http = double("http")
    expect(http).to receive(:get).with("/o/opac-api/title?id=CMP0315766&core=opere").and_return(response)
    allow(Net::HTTP).to receive(:start).and_yield(http)

    expect(described_class.call("CMP0315766")).to eq("Bach & Handel")
  end
end
