require "rails_helper"

RSpec.describe "IIIF record display", type: :view do
  let(:manifest_url) { "https://example.test/iiif/manifest.json?version=2&lang=en" }
  let(:url_subfield) { double(content: manifest_url) }
  let(:type_subfield) { double(content: "IIIF manifest (digitized source)") }
  let(:description_subfield) { double(content: "Digital copy") }
  let(:tag) { double }

  before do
    allow(tag).to receive(:fetch_first_by_tag).with("u").and_return(url_subfield)
    allow(tag).to receive(:fetch_first_by_tag).with("x").and_return(type_subfield)
    allow(tag).to receive(:fetch_first_by_tag).with("z").and_return(description_subfield)
  end

  it "renders declarative Diva markup without inline JavaScript" do
    allow(SecureRandom).to receive(:hex).and_return("viewer-id")
    item = double(get_iiif_tags: [tag])

    render partial: "marc_show/show_iiif", locals: { item: item }

    expect(rendered).to include('id="viewer-id"')
    expect(rendered).to include('class="muscat-diva-viewer"')
    expect(rendered).to include(
      'data-diva-manifest="https://example.test/iiif/manifest.json?version=2&amp;lang=en"'
    )
    expect(rendered).not_to include("<script")
  end

  it "links an IIIF 856 field to its embedded viewer" do
    editor_profile = double(get_label: "External resource")

    render partial: "marc_show/show_link", locals: {
      tag: tag,
      editor_profile: editor_profile,
      no_label: false,
    }

    expect(rendered).to include('href="#httpsexampletestiiifmanifestjson?version=2&amp;lang=en"')
  end
end
