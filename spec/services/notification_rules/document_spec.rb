require "rails_helper"

RSpec.describe NotificationRules::Document do
  let(:valid_document) do
    {
      version: 1,
      rules: [
        {
          model: "source",
          conditions: [
            { field: "composer", operator: "equals", value: "Bach" }
          ]
        }
      ],
      legacy_lines: []
    }
  end

  it "accepts a supported document" do
    expect(described_class.new(valid_document.to_json)).to be_valid
  end

  it "rejects unsupported models and fields" do
    valid_document[:rules][0][:model] = "unknown_model"
    valid_document[:rules][0][:conditions][0][:field] = "title"

    document = described_class.new(valid_document)

    expect(document).not_to be_valid
    expect(document.errors.join(" ")).to include("unsupported record type", "unsupported field")
  end

  it "accepts singular underscored multiword models" do
    {
      "inventory_item" => "title",
      "liturgical_feast" => "name",
      "standard_term" => "term",
      "standard_title" => "title",
      "work_node" => "title"
    }.each do |model, field|
      valid_document[:rules][0][:model] = model
      valid_document[:rules][0][:conditions][0][:field] = field

      expect(described_class.new(valid_document)).to be_valid
    end
  end

  it "rejects values the legacy parser cannot represent safely" do
    valid_document[:rules][0][:conditions][0][:value] = 'Bach: "Mass"'

    expect(described_class.new(valid_document)).not_to be_valid
  end

  it "rejects wildcard operators for exact-match fields" do
    valid_document[:rules][0][:conditions][0] = {
      field: "follow",
      operator: "contains",
      value: "Bach"
    }

    expect(described_class.new(valid_document).errors).to include(
      "rule 1, condition 1 only supports exact matching"
    )
  end
end
