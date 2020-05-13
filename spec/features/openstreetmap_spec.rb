require 'rails_helper'
require 'net/http'

RSpec.describe "OpenStreetmap" do
  it "is reachable" do
    res = Net::HTTP.get_response( URI.parse("https://www.openstreetmap.org"))
    expect(res).to be_a Net::HTTPOK
  end
end

