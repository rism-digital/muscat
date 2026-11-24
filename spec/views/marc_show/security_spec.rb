require "rails_helper"

Rails.application.reload_routes!

RSpec.describe "MARC display escaping", type: :view do
  let(:url) { "https://example.test/catalogue?a=1&b=2" }
  let(:payload) { '<img src=x onerror=alert(1)><script>alert(2)</script>' }

  def source_tag(field, value, code = "a")
    item = build(:source, marc_source: "=001  1\n=#{field}  ##$#{code}#{value}\n")
    item.marc.load_source(false)
    [item, item.marc.first_occurance(field)]
  end

  def document
    Nokogiri::HTML.fragment(rendered)
  end

  def expect_inert_payload
    expect(document.css("script, img, svg, [onerror], [onload]")).to be_empty
    expect(document.text).to include(payload)
  end

  it "escapes auto-tag text while retaining clickable URLs and literal punctuation" do
    item, tag = source_tag("260", "#{url} #{payload} & \"quoted\"")
    render partial: "marc_show/show_auto_tag", locals: {
      item: item, tag: tag, editor_profile: EditorConfiguration.get_default_layout(item), no_label: true
    }

    expect_inert_payload
    expect(document.at_css("a")["href"]).to eq(url)
    expect(document.text).to include('& "quoted"')
  end

  it "escapes legacy subfield text before auto-linking" do
    item, tag = source_tag("500", "#{url} #{payload}")
    render partial: "marc/show_subfield", locals: {
      item: item, tag: tag, subfield: tag.fetch_first_by_tag("a"), no_label: true
    }

    expect_inert_payload
    expect(document.at_css("a")["href"]).to eq(url)
  end

  it "escapes plain-text browse-helper output" do
    item, tag = source_tag("852", payload)
    render partial: "marc/show_subfield", locals: {
      item: item, tag: tag, subfield: tag.fetch_first_by_tag("a"), no_label: true
    }

    expect_inert_payload
  end

  it "retains generated links to related records" do
    item, tag = source_tag("596", "123", "c")
    render partial: "marc/show_subfield", locals: {
      item: item, tag: tag, subfield: tag.fetch_first_by_tag("c"), no_label: true
    }

    expect(document.at_css("a")["href"]).to eq("/admin/sources/123")
    expect(document.at_css("a").text).to eq("123")
  end

  it "retains explicit line breaks in legacy subfields" do
    item, tag = source_tag("500", "First{{brk}}Second")
    render partial: "marc/show_subfield", locals: {
      item: item, tag: tag, subfield: tag.fetch_first_by_tag("a"), no_label: true
    }

    expect(document.css("br").size).to eq(1)
    expect(document.text).to include("First", "Second")
  end

  it "escapes unknown identifier values and authority names while preserving known links" do
    marc = MarcPerson.new("=024  7 $a#{payload}$2UNKNOWN\n=024  7 $a123$2#{payload}\n=024  7 $a456$2DNB\n")
    marc.load_source(false)
    render partial: "marc_show/show_dnb_link", locals: {
      tag: marc.first_occurance("024"), no_label: true
    }

    expect_inert_payload
    expect(document.text).to include("UNKNOWN:", ": 123", "DNB: 456")
    expect(document.at_css("a")["href"]).to eq("http://d-nb.info/gnd/456")
  end

  ["javascript:alert(1)", "data:text/html,<script>alert(1)</script>", "java\tscript:alert(1)"].each do |unsafe_url|
    it "removes executable external link schemes #{unsafe_url.inspect}" do
      tag = double(fetch_first_by_tag: nil)
      allow(tag).to receive(:fetch_first_by_tag).with("u").and_return(double(content: unsafe_url))
      allow(tag).to receive(:fetch_first_by_tag).with("z").and_return(double(content: "External resource"))
      render partial: "marc_show/show_link", locals: { tag: tag, no_label: true }

      expect(document.css("a[href]")).to be_empty
      expect(document.text).to include("External resource")
    end
  end

  it "preserves safe external URLs and escapes their labels" do
    tag = double(fetch_first_by_tag: nil)
    allow(tag).to receive(:fetch_first_by_tag).with("u").and_return(double(content: url))
    allow(tag).to receive(:fetch_first_by_tag).with("z").and_return(double(content: payload))
    render partial: "marc_show/show_link", locals: { tag: tag, no_label: true }

    expect_inert_payload
    expect(document.at_css("a")["href"]).to eq(url)
    expect(document.at_css("a")["target"]).to eq("_blank")
  end
end
