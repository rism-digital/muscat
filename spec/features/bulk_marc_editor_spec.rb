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
    jobs_before = Delayed::Job.count
    click_button "Preview changes"
    expect(page).to have_content("No records have been saved")
    expect(Delayed::Job.count).to eq(jobs_before)
    accept_confirm { find('input[value^="Apply to all"]').click }
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
    click_button "Preview changes"
    expect(page).to have_content("must include its master subfield")
    expect(find("#bulk_marc_tag").value).to eq("700")
    expect(find("#bulk_marc_subfield").value).to eq("4")
    expect(find("#bulk_marc_value").value).to eq("edt")
  end

  it "shows record diffs, changes sample size, and preserves the edit when returning" do
    folder.update!(folder_type: "Publication")
    record = create(:publication, wf_owner: admin.id)
    folder.add_item(record)
    visit bulk_marc_edit_admin_folder_path(folder)
    choose_code("bulk_marc_tag", "500")
    choose_code("bulk_marc_subfield", "a")
    fill_in "bulk_marc_value", with: "Preview note"
    click_button "Preview changes"
    expect(page).to have_content("No records have been saved")
    expect(page).to have_css(".diff_table ins", text: "Preview note")
    expect(record.reload.marc_source).not_to include("Preview note")
    expect(Delayed::Job.count).to eq(0)
    old_draft_id = BulkMarcEditDraft.last.id
    select "25", from: "Preview sample size"
    click_button "Refresh preview"
    expect(page).to have_css("input[name='draft_id']:not([value='#{old_draft_id}'])", visible: :all)
    expect(find("#sample_size").value).to eq("25")
    expect(BulkMarcEditDraft.exists?(old_draft_id)).to be(false)
    expect(BulkMarcEditDraft.count).to eq(1)
    page.execute_script("window.scrollTo(0, 0)")
    page.save_screenshot("/tmp/muscat-bulk-marc-preview.png")
    click_link "Back to edit"
    expect(find("#bulk_marc_tag").value).to eq("500")
    expect(find("#bulk_marc_value").value).to eq("Preview note")
    click_button "Preview changes"
    expect(page).to have_content("No records have been saved")
    expect(BulkMarcEditDraft.count).to eq(1)
    accept_confirm { click_button "Apply to all 1 record" }
    expect(page).to have_content("Bulk MARC edit job started")
  end
end
