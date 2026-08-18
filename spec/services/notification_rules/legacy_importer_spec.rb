require "rails_helper"

RSpec.describe NotificationRules::LegacyImporter do
  it "imports AND conditions and wildcard operators" do
    document = described_class.call('source composer:"Bach*" lib_siglum:"CH-A"')

    expect(document["legacy_lines"]).to be_empty
    expect(document["rules"]).to eq(
      [
        {
          "model" => "source",
          "conditions" => [
            { "field" => "composer", "operator" => "starts_with", "value" => "Bach" },
            { "field" => "lib_siglum", "operator" => "equals", "value" => "CH-A" }
          ]
        }
      ]
    )
  end

  it "imports a model-independent follow rule" do
    document = described_class.call('follow:"Rodolfo Zitellini"')

    expect(document["rules"].first).to include(
      "model" => "all",
      "conditions" => [
        { "field" => "follow", "operator" => "equals", "value" => "Rodolfo Zitellini" }
      ]
    )
  end

  it "imports singular underscored multiword models" do
    document = described_class.call("standard_term term:Motet\nstandard_title title:Mass")

    expect(document["legacy_lines"]).to be_empty
    expect(document["rules"].map { |rule| rule["model"] }).to eq(
      ["standard_term", "standard_title"]
    )
  end

  it "preserves unsupported and malformed rules verbatim" do
    document = described_class.call("source unknown_field:Mass\nnot a rule")

    expect(document["rules"]).to be_empty
    expect(document["legacy_lines"]).to eq(["source unknown_field:Mass", "not a rule"])
  end
end
