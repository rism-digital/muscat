RSpec.describe Institution do

  describe "#update_workgroups" do
    context "update workgroups should trigger update workgroups after creating new institution with siglum" do
      before_size = Workgroup.where(:name => 'Germany').take.institutions.size
      institution = Institution.create(:name => "Entenhausen", :siglum => "D-Enteh")
      after_size = Workgroup.where(:name => 'Germany').take.institutions.size
      it "compares the sizes of depending workgroups" do
        expect((before_size + 1)).to be == after_size
      end
      institution.destroy
    end
  end
end
 
