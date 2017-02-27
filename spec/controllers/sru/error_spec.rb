describe SruController, :type => :controller do
  render_views
  context "MaximumRecords should be limited to 100"
  it "returns the error page with limitiation" do
    get "service", {:query => 'Bach', :operation => "searchRetrieve", :maximumRecords => 200}
    doc = Nokogiri::XML(response.body)
    diag = "http://www.loc.gov/zing/srw/diagnostic/"
    max = doc.xpath("//diag:message", "diag" => diag).first.content
    expect(max).to match(/MaximumRecords is limited/)
  end
end

