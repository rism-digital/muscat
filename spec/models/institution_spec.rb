RSpec.describe Institution, solr: true do

  describe "#update_workgroups" do
    let!(:workgroup) { FactoryBot.create(:workgroup)  }

    it "compares the sizes of depending workgroups" do
      before_size = Workgroup.where(:name => 'Germany').take.institutions.size
      institution = Institution.create(:name => "Entenhausen", :siglum => "D-Enteh")
      after_size = Workgroup.where(:name => 'Germany').take.institutions.size
      expect((before_size + 1)).to be == after_size
      institution.destroy
    end
  end
end

