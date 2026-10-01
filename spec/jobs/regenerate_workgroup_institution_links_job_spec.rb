require "rails_helper"

RSpec.describe RegenerateWorkgroupInstitutionLinksJob, type: :job do
  it "regenerates institution links for every workgroup" do
    workgroup = instance_double(Workgroup)

    expect(workgroup).to receive(:change_institutions)
    expect(Workgroup).to receive(:find_each).and_yield(workgroup)

    described_class.new.perform
  end
end
