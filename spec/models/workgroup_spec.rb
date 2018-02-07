RSpec.describe "solr result of workgroup total sources" do
  let!(:user) { FactoryBot.create(:user)  }
  it "should return solr result set if source exist" do
    FactoryBot.create(:manuscript_source)
    Sunspot.index![Source]
    ix = Statistics::Workgroup.sources_by_month(Time.parse("2017-01-01"), Time.now, [Workgroup.last])
    f = Statistics::Spreadsheet.new(ix)
    expect(f.objects.last.row[Time.now.strftime("%Y-%m")]).to be == 1
  end
  
  it "should return zero set if there is no source" do
    ix = Statistics::Workgroup.sources_by_month(Time.parse("2017-01-01"), Time.now, [Workgroup.last])
    f = Statistics::Spreadsheet.new(ix)
    expect(f.objects.last.row[Time.now.strftime("%Y-%m")]).to be == 0
  end

end
