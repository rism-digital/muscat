describe "solr result of workgroup total sources" do
  it "should return solr result set of sources" do
    ix = Statistic::Workgroup.sources_by_month(Time.now-1.year, Time.now, Workgroup.where(:id => 1))
    f = Statistic::Factory.new(ix)
    expect(f.objects.first.row["2016-10"]).to be == 574
  end
end
