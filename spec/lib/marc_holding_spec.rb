require "rails_helper"

RSpec.describe MarcHolding do
  subject(:marc) { described_class.allocate }

  def subfield(content)
    double(content: content)
  end

  def tag(url:, type:, description: nil)
    double.tap do |marc_tag|
      allow(marc_tag).to receive(:fetch_first_by_tag).with("u").and_return(subfield(url))
      allow(marc_tag).to receive(:fetch_first_by_tag).with("x").and_return(subfield(type))
      allow(marc_tag).to receive(:fetch_first_by_tag).with("z").and_return(description && subfield(description))
    end
  end

  def provide_tags(*tags)
    allow(marc).to receive(:each_by_tag).with("856") do |&block|
      tags.each(&block)
    end
  end

  describe "#digital_object_links" do
    it "returns digitized resources on other sites" do
      provide_tags(
        tag(url: "https://example.test/digital", type: "Digitized source", description: "Digital copy"),
        tag(url: "https://example.test/manifest.json", type: "IIIF manifest")
      )

      expect(marc.digital_object_links).to eq([
        { url: "https://example.test/digital", description: "Digital copy" }
      ])
    end

    it "ignores missing, malformed, and non-web URLs" do
      provide_tags(
        tag(url: nil, type: "Digitized source"),
        tag(url: "javascript:alert(1)", type: "Digitized source"),
        tag(url: "not a URL", type: "IIIF manifest"),
        tag(url: "https://example.test/file", type: "Other")
      )

      expect(marc.digital_object_links).to be_empty
      expect(marc.digital_object?).to eq(false)
    end
  end
end
