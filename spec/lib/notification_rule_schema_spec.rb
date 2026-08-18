require "rails_helper"

RSpec.describe NotificationRuleSchema do
  it "defines the canonical singular underscored model names" do
    expect(described_class::MODELS).to include(
      "inventory_item",
      "liturgical_feast",
      "standard_term",
      "standard_title",
      "work_node"
    )
  end

  it "provides one field definition to the matcher and visual editor" do
    editor_configuration = NotificationRules::Configuration.to_h

    expect(NotificationMatcher::ALLOWED_MODELS).to equal(described_class::MODELS)
    expect(NotificationMatcher::ALLOWED_PROPERTIES).to equal(described_class::FIELDS)
    expect(editor_configuration[:models]).to equal(described_class::MODELS_WITH_ALL)
    expect(editor_configuration[:fields]).to equal(described_class::FIELDS)
  end

  it "normalizes Rails models to their singular underscored names" do
    expect(described_class.model_name_for(InventoryItem)).to eq("inventory_item")
    expect(described_class.model_name_for(StandardTerm)).to eq("standard_term")
  end
end
