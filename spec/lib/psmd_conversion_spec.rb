require "rails_helper"
require Rails.root.join("housekeeping/psmd/psmd_conversion").to_s

RSpec.describe PsmdConversion do
  describe ".convert_508_html_to_markdown" do
    it "preserves formatting and paragraphs while converting legacy characters" do
      pseudo_html = <<~HTML
        Dedication<p>First ſection with <i>italics æ</i>.<br>Second line.</p>
        <p>Next <sup>MO</sup> paragraph.</p>
      HTML

      markdown = described_class.convert_508_html_to_markdown(pseudo_html)

      expect(markdown).to eq(<<~MARKDOWN.strip)
        Dedication

        First section with _italics ae_.  
        Second line.

        Next ^(MO) paragraph.
      MARKDOWN
    end
  end

  describe ".extract_508_markdown" do
    it "combines all 508 subfields in their original order" do
      subfield = Struct.new(:content)
      marc = {
        "508" => [
          { "a" => [subfield.new("<p>First paragraph.</p>")] },
          { "a" => [subfield.new("<p>Second paragraph.</p>")] }
        ]
      }

      expect(described_class.extract_508_markdown(marc)).to eq("First paragraph.\n\nSecond paragraph.")
    end
  end
end
