require "rails_helper"

RSpec.describe "folder action modules", type: :routing do
  {
    get: %w[bulk_marc_edit choose_owner],
    post: %w[preview_bulk_marc_edit run_bulk_marc_edit change_owner publish unpublish make_catalogue export_folder reindex validate_folder],
    patch: %w[reset_expiration]
  }.each do |method, actions|
    actions.each do |action|
      it "registers #{action} with its existing HTTP method" do
        path = "/admin/folders/1/#{action}"
        expect(method => path).to route_to(controller: "admin/folders", action: action, id: "1")
        expect(get: path).not_to be_routable unless method == :get
      end
    end
  end
end
