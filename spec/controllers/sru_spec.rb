require 'rails_helper'

RSpec.describe SruController, :type => :controller do
  render_views
  
  context "MaximumRecords should be limited to 100" do
    it "returns the error page with limitiation" do
      get "service", {:query => 'Bach', :operation => "searchRetrieve", :maximumRecords => 200}
      doc = Nokogiri::XML(response.body)
      diag = "http://www.loc.gov/zing/srw/diagnostic/"
      max = doc.xpath("//diag:message", "diag" => diag).first.content
      expect(max).to match(/MaximumRecords is limited/)
    end
  end

  context "Default action should return the explain page" do
    it "returns the explain page" do
      get "service"
      doc = Nokogiri::XML(response.body)
      namespace="http://explain.z3950.org/dtd/2.0/" 
      hostinfo = doc.xpath("//ns:serverInfo/ns:host", "ns" => namespace).first.content
      expect(hostinfo).to be == "beta.rism.info"
    end
  end

end

