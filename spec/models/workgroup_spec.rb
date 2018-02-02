RSpec.describe "solr result of workgroup total sources" do
  let(:workgoup) { FactoryBot.create(:workgroup)  }
  it "should return solr result set of sources" do
    binding.pry
    ix = Statistics::Workgroup.sources_by_month(Time.parse("2016-01-01"), Time.parse("2017-01-01"), Workgroup.where(:id => 1))
    f = Statistics::Spreadsheet.new(ix)
    expect(f.objects.first.row["2016-10"]).to be == 574
  end
end
