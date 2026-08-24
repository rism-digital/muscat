require "rails_helper"

RSpec.describe AwesomePrint::MarcFormatter do
  subject(:formatter) do
    AwesomePrint::Formatter.new(AwesomePrint::Inspector.new(plain: true))
  end

  let(:marc_source) do
    <<~'MARC'
      =001  12345
      =245  10$aA title$bA subtitle
      =700  1#$aA composer
    MARC
  end

  let(:marc) { MarcSource.new(marc_source, MarcSource::RECORD_TYPES[:source]) }

  before do
    allow(formatter).to receive(:colorize) do |text, type|
      "<#{type}>#{text}</#{type}>"
    end
  end

  it "uses the MARC formatter only for Marc objects" do
    expect(formatter.cast(marc, :marc_source)).to eq(:muscat_marc)
    expect(formatter.cast("MARC", :string)).to eq(:self)
  end

  it "colors tags, control-field values, indicators, subfield codes, and values" do
    output = formatter.format(marc, :marc_source)

    expect(output).to include("<date>=001</date>  <variable>12345</variable>")
    expect(output).to include(
      "<date>=245</date>  <method>1</method><method>0</method>" \
      "<class>$a</class><variable>A title</variable>" \
      "<class>$b</class><variable>A subtitle</variable>"
    )
  end

  it "formats a copy without loading or changing the original object" do
    expect(marc.loaded).to be(false)

    formatter.format(marc, :marc_source)

    expect(marc.loaded).to be(false)
    expect(marc.root.children).to be_empty
  end

  it "does not duplicate fields when the original object is already loaded" do
    marc.load_source(false)
    before_formatting = marc.to_marc

    2.times { formatter.format(marc, :marc_source) }

    expect(marc.to_marc).to eq(before_formatting)
  end
end
