describe SruController, :type => :controller do
  render_views
  context "Default action should return the explain page"
  it "returns the explain page" do
    get "service"
    doc = Nokogiri::XML(response.body)
    namespace="http://explain.z3950.org/dtd/2.0/" 
    hostinfo = doc.xpath("//ns:serverInfo/ns:host", "ns" => namespace).first.content
    expect(hostinfo).to be == "beta.rism.info"
  end
end

