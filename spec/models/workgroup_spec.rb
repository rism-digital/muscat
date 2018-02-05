RSpec.describe "solr result of workgroup total sources" do
  let!(:user) { FactoryBot.create(:user)  }
  let!(:source) {FactoryBot.create(:source, wf_owner: user.id)}
  it "should return solr result set of sources" do
    ix = Statistics::Workgroup.sources_by_month(Time.parse("2017-01-01"), Time.now, [Workgroup.last])
    f = Statistics::Spreadsheet.new(ix)
    expect(f.objects.last.row[Time.now.strftime("%Y-%m")]).to be == 1
  end
end
