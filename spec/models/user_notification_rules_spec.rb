require "rails_helper"

RSpec.describe User, type: :model do
  it "writes structured and legacy rules together" do
    user = build(:user)
    user.notification_rules_json = {
      version: 1,
      rules: [
        {
          model: "source",
          conditions: [
            { field: "composer", operator: "starts_with", value: "Bach" },
            { field: "lib_siglum", operator: "equals", value: "CH-A" }
          ]
        }
      ],
      legacy_lines: []
    }.to_json

    user.valid?

    expect(user.notification_rules).to include("version" => 1)
    expect(user.notifications).to eq('composer:"Bach*" lib_siglum:"CH-A"')
  end

  it "lazily exposes existing legacy rules as JSON" do
    user = build(:user, notifications: 'follow:"Rodolfo Zitellini"', notification_rules: nil)

    document = JSON.parse(user.notification_rules_json)

    expect(document["rules"].first["model"]).to eq("all")
    expect(document["rules"].first["conditions"].first["value"]).to eq("Rodolfo Zitellini")
  end

  it "does not overwrite legacy rules unless builder JSON is assigned" do
    user = build(:user, notifications: "composer:Bach", notification_rules: nil)

    user.valid?

    expect(user.notifications).to eq("composer:Bach")
    expect(user.notification_rules).to be_nil
  end
end
