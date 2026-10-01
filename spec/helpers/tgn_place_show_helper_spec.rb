require "rails_helper"

RSpec.describe TgnPlaceShowHelper, type: :helper do
  def marc_tag(tag: "370", authority: "tgn", url: "https://vocab.getty.edu/tgn/7006660")
    instance_double(
      MarcNode,
      tag: tag,
      fetch_first_by_tag: nil,
    ).tap do |marc_tag|
      allow(marc_tag).to receive(:fetch_first_by_tag).with("2")
        .and_return(instance_double(MarcNode, content: authority))
      allow(marc_tag).to receive(:fetch_first_by_tag).with("u")
        .and_return(instance_double(MarcNode, content: url))
    end
  end

  it "extracts the TGN identifier from a TGN-backed 370 field" do
    expect(helper.associated_place_tgn_id(marc_tag)).to eq("7006660")
  end

  it "accepts HTTP URLs, uppercase authority codes, and a trailing slash" do
    tag = marc_tag(authority: "TGN", url: "http://vocab.getty.edu/tgn/7006660/")

    expect(helper.associated_place_tgn_id(tag)).to eq("7006660")
  end

  it "ignores fields other than 370" do
    expect(helper.associated_place_tgn_id(marc_tag(tag: "371"))).to be_nil
  end

  it "ignores 370 fields from another authority" do
    expect(helper.associated_place_tgn_id(marc_tag(authority: "gnd"))).to be_nil
  end

  it "ignores malformed TGN URLs" do
    expect(helper.associated_place_tgn_id(marc_tag(url: "https://example.org/tgn/7006660"))).to be_nil
  end
end
