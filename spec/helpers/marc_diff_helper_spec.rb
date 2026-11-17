require "rails_helper"

RSpec.describe MarcDiffHelper, type: :helper do
  def marc(source)
    MarcPublication.new(source).tap { |value| value.load_source(false) }
  end

  let(:profile) { EditorConfiguration.get_default_layout(Publication) }

  it "compares arbitrary MARC, including insertions, deletions, and control fields" do
    before = marc("=003  Old\n=500  #\#$aKeep\n=500  #\#$aRemove\n")
    after = marc("=003  New\n=500  #\#$aKeep\n=500  #\#$aAdded\n")
    rows = helper.marc_diff_rows(VersionChecker.compare_marc(before, after), profile)
    expect(rows.map { |row| row[:code] }).to include("003", "500$a")
    html = rows.map { |row| row[:html] }.join
    expect(html).to include("Old", "New", "Remove", "Added")
    expect(html).not_to include("Keep")
  end

  it "escapes MARC values before adding diff markup" do
    before = marc("=500  #\#$aOld\n")
    after = marc("=500  #\#$a<script>alert(1)</script>\n")
    rows = helper.marc_diff_rows(VersionChecker.compare_marc(before, after), profile)
    expect(rows.first[:html]).to include("&lt;script&gt;")
    expect(rows.first[:html]).not_to include("<script>")
    expect(rows.first[:html]).to include('<ins class="differ">')
  end

  it "preserves the persisted-version comparison API" do
    record = create(:publication)
    record.marc.add_tag_with_subfields("500", a: "Saved version note")
    record.save!
    tags, stages = VersionChecker.get_diff_with_next(record.versions.last.id)
    expect(stages).to eq([record.wf_stage, record.wf_stage])
    rows = helper.marc_diff_rows(tags, profile)
    expect(rows.map { |row| row[:html] }.join).to include("Saved version note")
  end
end
