require "rails_helper"

RSpec.describe "Bulk MARC Editor", type: :feature, js: true do
  let(:admin) { create(:admin) }
  let(:folder) { Folder.create!(name: "Bulk MARC example", folder_type: "Source", user: admin) }

  before do
    page.current_window.resize_to(1440, 1100)
    login_as admin, scope: :user
    visit bulk_marc_edit_admin_folder_path(folder)
  end

  def choose_code(id, code)
    find("##{id} option[value='#{code}']").select_option
  end

  def submit_operation
    accept_confirm { click_button "Start bulk edit" }
    expect(page).to have_content("Bulk MARC edit job started")
    Delayed::Job.last.payload_object.instance_variable_get(:@operations).first
  end

  it "submits a new tag with a free-text value" do
    choose_code("bulk_marc_tag", "500")
    choose_code("bulk_marc_subfield", "a")
    fill_in "bulk_marc_value", with: "Bulk note"
    expect(submit_operation).to include("action" => "add", "target" => "new", "tag" => "500", "subfield" => "a", "value" => "Bulk note")
  end

  it "submits a listed value with a condition on a linked-field ID" do
    choose_code("bulk_marc_tag", "700")
    choose_code("bulk_marc_subfield", "4")
    choose_code("bulk_marc_target", "matching")
    choose_code("bulk_marc_match_subfield", "0")
    fill_in "bulk_marc_match_value", with: "12345"
    choose_code("bulk_marc_value", "edt")
    page.execute_script("window.scrollTo(0, 0)")
    page.save_screenshot("/tmp/muscat-bulk-marc-editor.png")
    expect(submit_operation).to include("target" => "matching", "match_subfield" => "0", "match_value" => "12345", "value" => "edt")
  end

  it "allows independent custom values for both sides of a change" do
    choose_code("bulk_marc_tag", "700")
    choose_code("bulk_marc_subfield", "4")
    choose_code("bulk_marc_action", "change")
    select "Other value…", from: "bulk_marc_old_value"
    fill_in "bulk_marc_old_value_custom", with: "old-custom"
    select "Other value…", from: "bulk_marc_value"
    fill_in "bulk_marc_value_custom", with: "new-custom"
    expect(submit_operation).to include("action" => "change", "old_value" => "old-custom", "value" => "new-custom")
  end

  it "preserves the operation when the server rejects an incomplete new tag" do
    choose_code("bulk_marc_tag", "700")
    choose_code("bulk_marc_subfield", "4")
    choose_code("bulk_marc_value", "edt")
    accept_confirm { click_button "Start bulk edit" }
    expect(page).to have_content("must include its master subfield")
    expect(find("#bulk_marc_tag").value).to eq("700")
    expect(find("#bulk_marc_subfield").value).to eq("4")
    expect(find("#bulk_marc_value").value).to eq("edt")
  end
end
