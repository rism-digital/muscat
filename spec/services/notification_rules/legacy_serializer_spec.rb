require "rails_helper"

RSpec.describe NotificationRules::LegacySerializer do
  it "serializes AND conditions, exclusions, and OR rules" do
    document = {
      "version" => 1,
      "rules" => [
        {
          "model" => "source",
          "conditions" => [
            { "field" => "composer", "operator" => "starts_with", "value" => "Bach" },
            { "field" => "lib_siglum", "operator" => "equals", "value" => "CH-A" }
          ],
          "exclude" => { "own_changes" => true }
        },
        {
          "model" => "publication",
          "conditions" => [
            { "field" => "title", "operator" => "contains", "value" => "Motets" }
          ]
        }
      ],
      "legacy_lines" => ["source unknown_field:Mass"]
    }

    expect(described_class.call(document)).to eq(
      <<~RULES.chomp
        composer:"Bach*" lib_siglum:"CH-A" exclude:mine
        publication title:"*Motets*"
        source unknown_field:Mass
      RULES
    )
  end

  it "round-trips imported supported rules" do
    legacy = <<~RULES.chomp
      composer:"Bach*" lib_siglum:"CH-A"
      person full_name:"Clara Schumann"
      follow:"Rodolfo Zitellini"
    RULES

    imported = NotificationRules::LegacyImporter.call(legacy)

    expect(described_class.call(imported)).to eq(legacy)
  end
end
