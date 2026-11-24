require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::FoldersController, type: :controller do
  render_views

  let(:actor) { create(:admin) }
  let(:folder) { Folder.create!(name: "Folder items", folder_type: "Source", user: actor) }

  before { sign_in actor }

  def item_table
    Nokogiri::HTML(response.body).at_css(".muscat_panel table")
  end

  it "renders source fields and escapes sigla from both direct and inherited holdings" do
    parent = create(:source, id: 10)
    source = create(:source, parent_source: parent, std_title: "Sonatas", composer: "Composer",
      shelf_mark: "Shelf 123", lib_siglum: "D-B")
    create(:holding, source: source).update_columns(lib_siglum: "<script>alert(1)</script>")
    create(:holding, source: parent).update_columns(lib_siglum: "F-Pn")
    folder.add_item(source)

    get :show, params: { id: folder.id }

    expect(response).to have_http_status(:ok)
    expect(item_table.css("th").map(&:text)).to include(I18n.t(:filter_wf_stage))
    expect(item_table.text).to include("Sonatas", "Composer", "Shelf 123", "D-B", "F-Pn",
      "<script>alert(1)</script>")
    expect(item_table.css("script")).to be_empty
    expect(item_table.at_css(%(a[href="#{admin_source_path(source)}"]))).to be_present
    expect(item_table.at_css(%(a[href="#{edit_admin_source_path(source)}"])).text).to eq(I18n.t(:edit))
  end

  it "keeps the former ID and omits record links for deleted items" do
    folder.folder_items.create!(item_type: "Source", item_id: 999999)

    get :show, params: { id: folder.id }

    expect(response).to have_http_status(:ok)
    expect(item_table.text).to include("Item Deleted", "n/a, was 999999")
    expect(item_table.css("a")).to be_empty
  end

  it "renders workflow status for works" do
    work = create(:work)
    folder.update!(folder_type: "Work")
    folder.add_item(work)

    get :show, params: { id: folder.id }

    expect(response).to have_http_status(:ok)
    expect(item_table.css("th").map(&:text)).to include(I18n.t(:filter_wf_stage))
    expect(item_table.at_css("tbody tr td .status_tag").text).to eq("PUB")
  end

  (Folder::FOLDERABLE_TYPES - %w[Source Work]).each do |type|
    it "hides the Status column for #{type} folders" do
      folder.update!(folder_type: type)

      get :show, params: { id: folder.id }

      expect(response).to have_http_status(:ok)
      expect(item_table.css("th").map(&:text)).not_to include(I18n.t(:filter_wf_stage))
    end
  end

  it "renders user fields and linked workgroups for user folders" do
    folder.update!(folder_type: "User")
    folder.add_item(actor)
    workgroup = actor.workgroups.first
    workgroup.institutions.clear

    get :show, params: { id: folder.id }

    expect(response).to have_http_status(:ok)
    expect(item_table.text).to include(actor.name, actor.email)
    link = item_table.at_css(%(a[href="#{admin_workgroup_path(workgroup)}"]))
    expect(link.text).to eq(workgroup.name)
    expect(link["title"]).to eq(I18n.t(:workgroup_no_sigla))
  end

  context "as an editor viewing someone else's user record" do
    let(:actor) { create(:editor) }

    it "offers View without Edit when the record cannot be edited" do
      user = create(:user, id: 50, username: "other", email: "other@example.org")
      folder.update!(folder_type: "User")
      folder.add_item(user)

      get :show, params: { id: folder.id }

      expect(response).to have_http_status(:ok)
      expect(item_table.at_css(%(a[href="#{admin_user_path(user)}"]))).to be_present
      expect(item_table.at_css(%(a[href="#{edit_admin_user_path(user)}"]))).to be_nil
    end
  end
end
