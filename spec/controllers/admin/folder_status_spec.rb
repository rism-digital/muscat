require "rails_helper"

Rails.application.reload_routes!

RSpec.describe Admin::FoldersController, type: :controller do
  render_views

  it "shows PUB, UNP, MIX, and a blank status in the folder list" do
    admin = create(:admin)
    sign_in admin
    published = create(:source, id: 1, wf_stage: :published)
    unpublished = create(:source, id: 2, wf_stage: :inprogress)
    contents = {
      "PUB" => [published],
      "UNP" => [unpublished],
      "MIX" => [published, unpublished],
      nil => []
    }
    folders = contents.map do |label, items|
      folder = Folder.create!(name: label || "Empty", folder_type: "Source", user: admin)
      items.each { |item| folder.add_item(item) }
      [label, folder]
    end

    I18n.with_locale(:de) { get :index }

    expect(response).to have_http_status(:ok)
    page = Nokogiri::HTML(response.body)
    folders.each do |label, folder|
      row = page.at_css("#folder_#{folder.id}")
      expect(row).to be_present
      badge = row.at_css(".status_tag")
      if label
        expect(badge.text).to eq(label)
        expect(badge["class"].split).to include("warning") if label == "MIX"
      else
        expect(badge).to be_nil
      end
    end
  end
end
