require "rails_helper"

RSpec.describe "publication publishing routes", type: :routing do
  %w[publish_works unpublish_works].each do |action|
    it "requires POST for #{action}" do
      path = "/admin/publications/1/#{action}"
      expect(post: path).to route_to(controller: "admin/publications", action: action, id: "1")
      expect(get: path).not_to be_routable
    end
  end
end
