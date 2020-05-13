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
      expect(hostinfo).to eq "beta.rism.info"
    end
  end

end

