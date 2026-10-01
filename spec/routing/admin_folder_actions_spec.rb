require "rails_helper"

RSpec.describe "admin folder action routing", type: :routing do
  %w[reindex publish unpublish export_folder validate_folder].each do |action|
    it "routes #{action} through POST, not GET" do
      path = "/admin/folders/1/#{action}"

      expect(post: path).to route_to(controller: "admin/folders", action: action, id: "1")
      expect(get: path).not_to be_routable
    end
  end

  it "routes reset_expiration through PATCH, not GET" do
    path = "/admin/folders/1/reset_expiration"

    expect(patch: path).to route_to(controller: "admin/folders", action: "reset_expiration", id: "1")
    expect(get: path).not_to be_routable
  end

  %w[do_create_new_folder do_append_to_folder].each do |action|
    it "routes #{action} through POST, not GET" do
      path = "/admin/sources/#{action}"

      expect(post: path).to route_to(controller: "admin/sources", action: action)
      expect(get: path).not_to route_to(controller: "admin/sources", action: action)
    end
  end
end
