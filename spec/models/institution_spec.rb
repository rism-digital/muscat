RSpec.describe Institution do

  describe "#update_workgroups" do
    let!(:workgroup) { FactoryBot.create(:workgroup)  }

    it "compares the sizes of depending workgroups" do
      binding.pry
      #context "update workgroups should trigger update workgroups after creating new institution with siglum" do
      before_size = Workgroup.where(:name => 'GB').take.institutions.size
      institution = Institution.create(:name => "Entenhausen", :siglum => "GB-Enteh")
      after_size = Workgroup.where(:name => 'GB').take.institutions.size
      binding.pry
      expect((before_size + 1)).to be == after_size
      institution.destroy
    end
  end
end

