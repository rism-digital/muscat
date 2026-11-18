require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::FoldersController, type: :controller do
  render_views

  let(:actor) { create(:admin) }
  let(:folder) { Folder.create!(name: "Bulk <script>alert(1)</script>", folder_type: "Source", user: actor) }
  let(:operation) { { action: "add", tag: "500", subfield: "a", target: "new", value: "New note" } }

  before { sign_in actor }

  it "shows the menu and a form populated with the complete MARC configuration" do
    get :show, params: { id: folder.id }
    expect(response.body).to include(bulk_marc_edit_admin_folder_path(folder))

    get :bulk_marc_edit, params: { id: folder.id }
    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    fields = JSON.parse(page.at_css('[data-bulk-marc-fields]').text)
    expect(fields.map { |field| field["code"] }).to include("001", "700", "500")
    expect(page.at_css('form[action="' + preview_bulk_marc_edit_admin_folder_path(folder) + '"]')["method"]).to eq("post")
    expect(response.body).not_to include("<script>alert(1)</script>")
  end

  it "enqueues validated operations with the session actor, ignoring forged job arguments" do
    expect(Delayed::Job).to receive(:enqueue) do |job|
      expect(job).to be_a(BulkMarcEditorJob)
      expect(job.instance_variable_get(:@requesting_user_id)).to eq(actor.id)
      expect(job.instance_variable_get(:@folder_id)).to eq(folder.id)
      expect(job.instance_variable_get(:@operations)).to eq([operation.stringify_keys])
      expect(job.instance_variable_get(:@modification_reason)).to eq("Correct cataloguing data")
      double(id: 123)
    end
    draft, = BulkMarcEditDraft.prepare(folder, actor, [operation], modification_reason: "Correct cataloguing data")
    post :run_bulk_marc_edit, params: {
      id: folder.id, draft_id: draft.id, operations: [operation.merge(value: "Forged")],
      modification_reason: "Forged reason", requesting_user_id: 999, model: "User"
    }
    expect(response).to redirect_to(admin_folder_path(folder))
  end

  it "does not enqueue invalid or malformed operations" do
    expect(Delayed::Job).not_to receive(:enqueue)
    [[], "bad", { action: "remove" }, [operation.merge(tag: "XYZ")], [operation.merge(action: "remove")]].each do |operations|
      post :preview_bulk_marc_edit, params: { id: folder.id, operations: operations, modification_reason: "Correct cataloguing data" }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  it "requires a nonblank modification reason and rejects oversized or nonscalar reasons" do
    expect(Delayed::Job).not_to receive(:enqueue)
    [nil, "", "   ", "...", "!!!", " — ; : ", "🙂", "x" * 256, ["not a scalar"]].each do |reason|
      expect do
        post :preview_bulk_marc_edit, params: { id: folder.id, operations: [operation], modification_reason: reason }
      end.not_to change(BulkMarcEditDraft, :count)
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Modification reason")
    end
  end

  it "stores a trimmed reason and uses it when refreshing a preview" do
    post :preview_bulk_marc_edit, params: {
      id: folder.id, operations: [operation], modification_reason: "  Correct attribution  "
    }
    expect(response).to have_http_status(:ok)
    draft = BulkMarcEditDraft.last
    expect(draft.modification_reason).to eq("Correct attribution")
    post :preview_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id, modification_reason: "Forged" }
    expect(response).to have_http_status(:ok)
    expect(BulkMarcEditDraft.last.modification_reason).to eq("Correct attribution")
    expect(response.body).to include("Correct attribution")
  end

  it "requires a reason before confirming a preview created before this field existed" do
    draft, = BulkMarcEditDraft.prepare(folder, actor, [operation], modification_reason: "Temporary fixture reason")
    draft.update_column(:modification_reason, nil)
    expect(Delayed::Job).not_to receive(:enqueue)
    post :run_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id }
    expect(response).to redirect_to(bulk_marc_edit_admin_folder_path(folder, draft_id: draft.id))
    expect(flash[:alert]).to include("Enter a modification reason")
    expect(draft.reload.confirmed_at).to be_nil
  end

  it "previews without enqueueing or changing records" do
    expect(Delayed::Job).not_to receive(:enqueue)
    expect do
      post :preview_bulk_marc_edit, params: { id: folder.id, operations: [operation], modification_reason: "Correct cataloguing data", sample_size: 100 }
    end.to change(BulkMarcEditDraft, :count).by(1)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("No records have been saved", "sample only")
    expect(BulkMarcEditDraft.last.sample_size).to eq(100)
  end

  it "requires a preview draft and accepts confirmation only once" do
    post :run_bulk_marc_edit, params: { id: folder.id, operations: [operation] }
    expect(response).to have_http_status(:unprocessable_entity)
    draft, = BulkMarcEditDraft.prepare(folder, actor, [operation], modification_reason: "Correct cataloguing data")
    expect do
      2.times { post :run_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id } }
    end.to change(Delayed::Job, :count).by(1)
    expect(flash[:alert]).to include("already been confirmed")
  end

  it "cannot confirm another admin's draft" do
    draft, = BulkMarcEditDraft.prepare(folder, actor, [operation], modification_reason: "Correct cataloguing data")
    draft.update!(requesting_user_id: 999)
    expect(Delayed::Job).not_to receive(:enqueue)
    post :run_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id }
    expect(response).to redirect_to(bulk_marc_edit_admin_folder_path(folder))
    expect(flash[:alert]).to include("no longer available")
  end

  it "handles old preview tabs after cleanup" do
    draft, = BulkMarcEditDraft.prepare(folder, actor, [operation], modification_reason: "Correct cataloguing data")
    draft.destroy!
    expect(Delayed::Job).not_to receive(:enqueue)
    get :bulk_marc_edit, params: { id: folder.id, draft_id: draft.id }
    expect(response).to redirect_to(bulk_marc_edit_admin_folder_path(folder))
    post :preview_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id }
    expect(response).to redirect_to(bulk_marc_edit_admin_folder_path(folder))
    post :run_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id }
    expect(response).to redirect_to(bulk_marc_edit_admin_folder_path(folder))
    expect(flash[:alert]).to include("no longer available")
  end

  it "removes the previous preview when refreshing the sample or editing the operation" do
    draft, = BulkMarcEditDraft.prepare(folder, actor, [operation], modification_reason: "Correct cataloguing data")
    post :preview_bulk_marc_edit, params: { id: folder.id, draft_id: draft.id, sample_size: 25 }
    expect(BulkMarcEditDraft.exists?(draft.id)).to be(false)
    replacement = BulkMarcEditDraft.last
    expect(replacement.sample_size).to eq(25)
    post :preview_bulk_marc_edit, params: {
      id: folder.id, replace_draft_id: replacement.id, operations: [operation.merge(value: "Edited")], modification_reason: "Edited reason"
    }
    expect(BulkMarcEditDraft.exists?(replacement.id)).to be(false)
    expect(BulkMarcEditDraft.last.operations.first["value"]).to eq("Edited")
    expect(BulkMarcEditDraft.count).to eq(1)
  end

  it "rejects a folder whose contents have no MARC configuration" do
    folder.update!(folder_type: "User")
    expect(Delayed::Job).not_to receive(:enqueue)
    get :bulk_marc_edit, params: { id: folder.id }
    expect(response).to have_http_status(:unprocessable_entity)
    post :preview_bulk_marc_edit, params: { id: folder.id, operations: [operation] }
    expect(response).to have_http_status(:unprocessable_entity)
  end

  [:editor, :cataloger, :guest].each do |role|
    context "as a #{role}" do
      let(:actor) { create(role) }

      it "rejects direct requests even when the user owns the folder" do
        expect(Delayed::Job).not_to receive(:enqueue)
        get :bulk_marc_edit, params: { id: folder.id }
        expect(response).to have_http_status(:forbidden)
        [:html, :json].each do |format|
          [:preview_bulk_marc_edit, :run_bulk_marc_edit].each do |action|
            post action, params: { id: folder.id, operations: [operation] }, format: format
            expect(response).to have_http_status(:forbidden)
          end
        end
      end
    end
  end
end
