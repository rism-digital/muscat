RSpec.describe "Dependency_checks" do
  before(:each) do
    FactoryBot.create(:manuscript_source)
  end

  context "Simple dependency check" do
    let!(:feast) { create :liturgical_feast }
    it "institution could not be destroyed due to dependencies" do
      i = Institution.find(30000655)
      expect { i.check_dependencies  }.to raise_error(ActiveRecord::RecordNotDestroyed, "Record #{i.class} #{i.id} has active dependencies [referring_sources]")
    end
    
    it "feast without any dependencies can be destroyed" do
      expect { feast.check_dependencies  }.to_not raise_error
    end

  end
end
