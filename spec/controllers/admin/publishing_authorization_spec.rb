require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::PublicationsController, type: :controller do
  let(:actor) { create(:admin) }
  let(:publication) { create(:publication, user: actor) }

  before { sign_in actor }

  [:publish_works, :unpublish_works].each do |action|
    [:admin, :editor].each do |role|
      context "as #{role}" do
        let(:actor) { create(role) }

        it "allows #{action}" do
          expect(Delayed::Job).to receive(:enqueue) do |job|
            expect(job).to be_a(PublishItemsJob)
            expect(job.instance_variable_get(:@parent_obj_id)).to eq(publication.id)
            expect(job.instance_variable_get(:@relation)).to eq(:referring_works)
            expect(job.instance_variable_get(:@action)).to eq(action == :publish_works ? :publish : :unpublish)
            double(id: 123)
          end

          post action, params: { id: publication.id }
          expect(response).to redirect_to(admin_publication_path(publication))
        end
      end
    end

    [:guest, :cataloger].each do |role|
      context "as #{role}" do
        let(:actor) { create(role) }

        it "denies #{action} even for an owned publication" do
          expect(Delayed::Job).not_to receive(:enqueue)
          post action, params: { id: publication.id }, format: :json
          expect(response).to have_http_status(:unauthorized)
        end
      end
    end

    it "does not enqueue #{action} without authentication" do
      publication_id = publication.id
      sign_out actor
      expect(Delayed::Job).not_to receive(:enqueue)
      post action, params: { id: publication_id }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end

RSpec.describe Admin::FoldersController, type: :controller do
  let(:actor) { create(:admin) }
  let(:folder) { Folder.create!(name: "Publishing test", folder_type: "Source", user: actor) }

  before { sign_in actor }

  [:publish, :unpublish].each do |action|
    [:admin, :editor].each do |role|
      context "as #{role}" do
        let(:actor) { create(role) }

        it "allows folder #{action}" do
          expect(Delayed::Job).to receive(:enqueue).with(an_instance_of(PublishItemsJob)).and_return(double(id: 123))
          post action, params: { id: folder.id }
          expect(response).to redirect_to(admin_folder_path(folder))
        end
      end
    end

    context "as a guest" do
      let(:actor) { create(:guest) }

      it "denies folder #{action}" do
        expect(Delayed::Job).not_to receive(:enqueue)
        post action, params: { id: folder.id }, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  context "as a cataloguer" do
    let(:actor) { create(:cataloger) }

    it "can publish source folders within their institution domain" do
      institution = create(:institution)
      actor.workgroups.first.institutions << institution
      source = create(:source, lib_siglum: institution.siglum)
      folder.add_item(source)
      expect(Delayed::Job).to receive(:enqueue).with(an_instance_of(PublishItemsJob)).and_return(double(id: 123))
      post :publish, params: { id: folder.id }
      expect(response).to redirect_to(admin_folder_path(folder))
    end

    it "cannot publish a source folder outside their institution domain" do
      source = create(:source, lib_siglum: "OUTSIDE-DOMAIN")
      folder.add_item(source)

      expect(Delayed::Job).not_to receive(:enqueue)
      post :publish, params: { id: folder.id }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "cannot publish a folder of another record type" do
      folder.update!(folder_type: "Work")
      expect(Delayed::Job).not_to receive(:enqueue)
      post :publish, params: { id: folder.id }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it "cannot unpublish even an owned folder" do
      expect(Delayed::Job).not_to receive(:enqueue)
      post :unpublish, params: { id: folder.id }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
