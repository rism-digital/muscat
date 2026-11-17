require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::FoldersController, type: :controller do
  render_views

  let(:actor) { create(:admin) }
  let(:folder) { Folder.create!(name: "Sidebar", folder_type: "Source", user: actor) }

  before { sign_in actor }

  def sidebar
    Nokogiri::HTML(response.body).at_css("#sidebar")
  end

  it "renders shared and folder actions once with their existing HTTP methods" do
    get :show, params: { id: folder.id }
    expect(response).to have_http_status(:ok)
    %w[reindex publish unpublish export_folder validate_folder].each do |action|
      links = sidebar.css(%(a[href="#{send("#{action}_admin_folder_path", folder)}"]))
      expect(links.length).to eq(1)
      expect(links.first["data-method"]).to eq("post")
    end
    %w[bulk_marc_edit choose_owner].each do |action|
      expect(sidebar.css(%(a[href="#{send("#{action}_admin_folder_path", folder)}"])).length).to eq(1)
    end
    expect(sidebar.at_css(%(a[href="#{reset_expiration_admin_folder_path(folder)}"]))["data-method"]).to eq("patch")
    expect(sidebar.at_css(%(a[href="#{admin_folders_path}"]))).to be_present
    expect(sidebar.css("a.muscat_icon_link_download").length).to eq(4)
  end

  [:editor, :cataloger].each do |role|
    context "as a #{role}" do
      let(:actor) { create(role) }

      it "preserves export permissions and hides admin-only actions" do
        get :show, params: { id: folder.id }
        expect(response).to have_http_status(:ok)
        expect(sidebar.at_css(%(a[href="#{bulk_marc_edit_admin_folder_path(folder)}"]))).to be_nil
        expect(sidebar.at_css(%(a[href="#{choose_owner_admin_folder_path(folder)}"]))).to be_nil
        expect(sidebar.css("a.muscat_icon_link_download").length).to eq(role == :editor ? 4 : 2)
        expect(sidebar.at_css(%(a[href="#{validate_folder_admin_folder_path(folder)}"]))).to be_present
      end
    end
  end

  it "renders the Publication catalogue form separately from the link lists" do
    folder.update!(folder_type: "Publication")
    get :show, params: { id: folder.id }
    expect(sidebar.css("a.muscat_icon_link_download").length).to eq(1)
    expect(sidebar.at_css(%(a[href="#{validate_folder_admin_folder_path(folder)}"]))).to be_nil
    forms = sidebar.css(%(form[action="#{make_catalogue_admin_folder_path(folder)}"]))
    expect(forms.length).to eq(1)
    expect(forms.first["method"]).to eq("post")
    expect(forms.first.ancestors("form, ul")).to be_empty
    expect(forms.first.css("tr")).to be_empty
  end

  it "hides folder controls in record-selection mode, including the catalogue form" do
    folder.update!(folder_type: "Publication")
    get :show, params: { id: folder.id, select: "true" }
    expect(sidebar.at_css(%(a[href="#{bulk_marc_edit_admin_folder_path(folder)}"]))).to be_nil
    expect(sidebar.at_css(%(a[href="#{choose_owner_admin_folder_path(folder)}"]))).to be_nil
    expect(sidebar.css("a.muscat_icon_link_download")).to be_empty
    expect(sidebar.at_css(%(form[action="#{make_catalogue_admin_folder_path(folder)}"]))).to be_nil
  end

  it "hides MARC-only actions for unsupported folder contents" do
    folder.update!(folder_type: "User")
    get :show, params: { id: folder.id }
    expect(sidebar.at_css(%(a[href="#{bulk_marc_edit_admin_folder_path(folder)}"]))).to be_nil
    expect(sidebar.at_css(%(a[href="#{choose_owner_admin_folder_path(folder)}"]))).to be_nil
    expect(sidebar.css("a.muscat_icon_link_download")).to be_empty
  end
end

RSpec.describe Admin::PublicationsController, type: :controller do
  render_views

  it "keeps normal resource links and their methods without folder-specific controls" do
    admin = create(:admin)
    publication = create(:publication, wf_owner: admin.id)
    sign_in admin
    get :show, params: { id: publication.id }

    expect(response).to have_http_status(:ok)
    sidebar = Nokogiri::HTML(response.body).at_css("#sidebar")
    expect(sidebar.at_css(%(a[href="#{admin_publications_path}"]))).to be_present
    expect(sidebar.at_css(%(a[href="#{admin_publication_path(publication)}"][data-method="delete"]))).to be_present
    expect(sidebar.at_css(%(a[href="#{reindex_admin_publication_path(publication)}"]))["data-method"]).to be_nil
    expect(sidebar.at_css('a[href*="/admin/folders/"]')).to be_nil
    expect(sidebar.text).not_to include("Bulk MARC Editor")
  end
end
