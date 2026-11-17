require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::FoldersController, type: :controller do
  render_views

  let(:actor) { create(:admin) }
  let(:folder) { Folder.create!(name: "Ownership test", folder_type: "Source", user: actor) }
  let(:new_owner) do
    create(:cataloger, id: 50, username: "recipient", email: "recipient@example.org")
  end

  before { sign_in actor }

  it "shows the action and the existing autocomplete picker to admins" do
    get :show, params: { id: folder.id }
    expect(response.body).to include(choose_owner_admin_folder_path(folder))

    get :choose_owner, params: { id: folder.id }
    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    expect(page.at_css('input[name="new_owner_id"]')["data-value-property"]).to eq("shortid")
    expect(page.at_css('form[action="' + change_owner_admin_folder_path(folder) + '"]')["method"]).to eq("post")
  end

  it "enqueues the selected owner and the authenticated admin, ignoring a forged requester" do
    expect(Delayed::Job).to receive(:enqueue) do |job|
      expect(job).to be_a(ChangeOwnerJob)
      expect(job.instance_variable_get(:@user)).to eq(new_owner.id)
      expect(job.instance_variable_get(:@requesting_user_id)).to eq(actor.id)
      expect(job.instance_variable_get(:@parent_obj_class)).to eq(Folder)
      expect(job.instance_variable_get(:@relation)).to eq(:folder_items)
      double(id: 123)
    end

    post :change_owner, params: { id: folder.id, new_owner_id: new_owner.id, requesting_user_id: new_owner.id }

    expect(response).to redirect_to(admin_folder_path(folder))
  end

  [nil, "unknown", "999999999"].each do |invalid_owner|
    it "rejects invalid owner #{invalid_owner.inspect} without enqueueing" do
      expect(Delayed::Job).not_to receive(:enqueue)
      post :change_owner, params: { id: folder.id, new_owner_id: invalid_owner }
      expect(response).to redirect_to(choose_owner_admin_folder_path(folder))
    end
  end

  it "rejects folders without ownership support" do
    folder.update!(folder_type: "User")
    expect(Delayed::Job).not_to receive(:enqueue)
    post :change_owner, params: { id: folder.id, new_owner_id: new_owner.id }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  it "does not enqueue for an unauthenticated request" do
    folder_id = folder.id
    sign_out actor
    expect(Delayed::Job).not_to receive(:enqueue)

    post :change_owner, params: { id: folder_id, new_owner_id: 50 }, format: :json

    expect([302, 401]).to include(response.status)
  end

  context "as a guest" do
    let(:actor) { create(:guest) }

    it "rejects direct requests without enqueueing" do
      expect(Delayed::Job).not_to receive(:enqueue)
      post :change_owner, params: { id: folder.id, new_owner_id: actor.id }, format: :json
      expect([401, 403]).to include(response.status)
    end
  end

  [:editor, :cataloger].each do |role|
    context "as a #{role} who owns the folder" do
      let(:actor) { create(role) }

      it "hides the action and rejects direct HTML and JSON requests" do
        get :show, params: { id: folder.id }
        expect(response.body).not_to include(choose_owner_admin_folder_path(folder))

        expect(Delayed::Job).not_to receive(:enqueue)
        get :choose_owner, params: { id: folder.id }
        expect(response).to have_http_status(:forbidden)

        [:html, :json].each do |format|
          post :change_owner, params: { id: folder.id, new_owner_id: actor.id }, format: format
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
