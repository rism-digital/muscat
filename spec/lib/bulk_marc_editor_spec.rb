require "rails_helper"

RSpec.describe BulkMarcEditor do
  let(:editor) { described_class.new(Source) }

  def record_with(source)
    marc = MarcSource.new(source)
    marc.load_source(false)
    double(marc: marc)
  end

  def apply(record, **attributes)
    operation = { action: "add", tag: "700", subfield: "4", target: "all", value: "edt" }.merge(attributes)
    editor.apply(record, editor.validate_operations([operation]))
  end

  it "lists every configured tag and subfield, including control fields and fields outside FormOptions" do
    expected = []
    editor.marc_config.each_tag { |tag| expected << tag }
    expect(editor.fields.map { |field| field[:code] }).to eq(expected)
    editor.fields.each do |field|
      codes = []
      editor.marc_config.each_subtag(field[:code]) { |code, _| codes << code.to_s }
      expect(field[:subfields].map { |subfield| subfield[:code] }).to eq(codes)
    end
    expect(editor.fields.find { |field| field[:code] == "001" }[:subfields].first[:code]).to eq("")
  end

  it "resolves inline, shared, and grouped choices while retaining stored codes" do
    expect(editor.choices("031", "n").map { |choice| choice[:value] }).to include("xF")
    expect(editor.choices("041", "a").map { |choice| choice[:value] }).to include("eng")
    expect(editor.choices("031", "g")).to include(hash_including(group: kind_of(String)))
    expect(editor.choices("700", "4").map { |choice| choice[:value] }).to include("edt")
  end

  it "adds a subfield to every existing occurrence and leaves missing tags absent" do
    record = record_with("=700  1\#$aOne\n=700  1\#$aTwo\n")
    expect(apply(record)).to be(true)
    expect(record.marc["700"].map { |tag| tag["4"].first.content }).to eq(%w[edt edt])
    missing = record_with("=500  #\#$aNote\n")
    expect(apply(missing)).to be(false)
    expect(missing.marc["700"]).to be_empty
  end

  it "matches the condition within the same parent tag, including IDs" do
    record = record_with("=700  1\#$aOne$0123\n=700  1\#$aTwo$0456\n")
    apply(record, target: "matching", match_subfield: "0", match_value: "123")
    expect(record.marc["700"].map { |tag| tag["4"].map(&:content) }).to eq([["edt"], []])
  end

  it "makes no changes if the condition does not match" do
    record = record_with("=700  1\#$aOne\n")
    expect(apply(record, target: "matching", match_subfield: "a", match_value: "one")).to be(false)
  end

  it "creates a new tag separately from existing occurrences" do
    record = record_with("=500  #\#$aExisting\n")
    apply(record, tag: "500", subfield: "a", target: "new", value: "New")
    expect(record.marc["500"].map { |tag| tag["a"].first.content }).to eq(%w[Existing New])
  end

  it "changes all exact matches without substring or case-insensitive replacement" do
    record = record_with("=500  #\#$aold\n=500  #\#$aold words\n=500  #\#$aOld\n=500  #\#$aold\n")
    apply(record, tag: "500", subfield: "a", action: "change", old_value: "old", value: "new")
    expect(record.marc["500"].map { |tag| tag["a"].first.content }).to eq(["new", "old words", "Old", "new"])
  end

  it "skips identical additions and rejects conflicting non-repeatable subfields" do
    record = record_with("=500  #\#$aNote\n")
    expect(apply(record, tag: "500", subfield: "a", value: "Note")).to be(false)
    expect { apply(record, tag: "500", subfield: "a", value: "Other") }.to raise_error(BulkMarcEditor::InvalidOperation)
  end

  it "supports whole-field changes for control fields" do
    record = record_with("=003  Agency\n")
    apply(record, tag: "003", subfield: "", action: "change", old_value: "Agency", value: "Other")
    expect(record.marc["003"].first.content).to eq("Other")
  end

  it "rejects invalid fields, actions, conditions, and new tags missing their master" do
    [
      { tag: "XYZ" }, { subfield: "!" }, { action: "remove" },
      { target: "matching", match_subfield: "!", match_value: "123" },
      { target: "new", subfield: "4" }
    ].each do |attributes|
      expect { apply(record_with(""), **attributes) }.to raise_error(BulkMarcEditor::InvalidOperation)
    end
  end

  it "allows unlisted values and an ordered array of operations" do
    record = record_with("=500  #\#$aOld\n")
    operations = editor.validate_operations([
      { action: "change", tag: "500", subfield: "a", old_value: "Old", value: "Intermediate" },
      { action: "change", tag: "500", subfield: "a", old_value: "Intermediate", value: "Unlisted" }
    ])
    expect(editor.apply(record, operations)).to be(true)
    expect(record.marc["500"].first["a"].first.content).to eq("Unlisted")
  end
end
