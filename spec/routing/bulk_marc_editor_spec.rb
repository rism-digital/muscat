require "rails_helper"

RSpec.describe "bulk MARC editor routing", type: :routing do
  it "uses GET for the form and only POST for starting the job" do
    expect(get: "/admin/folders/1/bulk_marc_edit").to route_to(controller: "admin/folders", action: "bulk_marc_edit", id: "1")
    expect(post: "/admin/folders/1/run_bulk_marc_edit").to route_to(controller: "admin/folders", action: "run_bulk_marc_edit", id: "1")
    expect(get: "/admin/folders/1/run_bulk_marc_edit").not_to be_routable
  end
end
