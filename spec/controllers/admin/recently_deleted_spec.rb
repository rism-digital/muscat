require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::RecentlyDeletedController, type: :controller do
  render_views

  let(:admin) { create(:admin) }

  def deletion(type, age:, actor: "Cataloguer")
    PaperTrail::Version.create!(
      item_type: type, item_id: rand(100_000..999_999), event: "destroy",
      whodunnit: actor, object: { "marc_source" => "=001  12345" }.to_yaml,
      created_at: age.ago
    )
  end

  it "filters by type and rolling date range" do
    sign_in admin
    recent = deletion("Source", age: 2.hours)
    deletion("Source", age: 3.days)
    deletion("Institution", age: 2.hours)

    get :index, params: { range: "day", type: "Source" }

    expect(response).to have_http_status(:ok)
    expect(assigns(:versions).map(&:id)).to eq([recent.id])
    expect(response.body).to include("Cataloguer")
    expect(response.body).to have_css('form[action="/admin/recently_deleted"] select[name="range"]')
    expect(response.body).to have_css('form[action="/admin/recently_deleted"] select[name="type"]')
  end

  it "shows the saved record by version id" do
    sign_in admin
    version = deletion("Source", age: 2.hours)

    get :index, params: { version_id: version.id }

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("MARC21", "Properties")
  end

  it "denies editors even when they request the page directly" do
    sign_in create(:editor)

    get :index

    expect(response).not_to have_http_status(:ok)
  end
end
