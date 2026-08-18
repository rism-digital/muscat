require "rails_helper"

RSpec.describe NotificationMatcher do
  describe ".model_name_for" do
    it "returns singular underscored Rails model names" do
      expect(described_class.model_name_for(InventoryItem)).to eq("inventory_item")
      expect(described_class.model_name_for(LiturgicalFeast)).to eq("liturgical_feast")
      expect(described_class.model_name_for(StandardTerm)).to eq("standard_term")
      expect(described_class.model_name_for(StandardTitle)).to eq("standard_title")
      expect(described_class.model_name_for(WorkNode)).to eq("work_node")
    end
  end

  describe ".parse_line" do
    it "recognizes canonical singular multiword model names" do
      model, rules = described_class.parse_line("standard_term term:Motet")

      expect(model).to eq("standard_term")
      expect(rules).to eq([{ property: "term", pattern: "Motet" }])
    end

    it "does not recognize the former plural standard model names" do
      model, = described_class.parse_line("standard_terms term:Motet")

      expect(model).to eq("source")
    end
  end

  describe "#get_matches" do
    it "treats a single wildcard as a match even when the allowed property is empty" do
      person = Person.new
      user = instance_double(User, get_notifications: ["person life_dates:*"], name: "Cataloguer")

      expect(described_class.new(person, user).get_matches).to eq(["life_dates *"])
    end

    it "matches a canonical standard_term rule against a StandardTerm" do
      term = StandardTerm.new(term: "Motet")
      user = instance_double(User, get_notifications: ["standard_term term:Motet"], name: "Cataloguer")

      expect(described_class.new(term, user).get_matches).to eq(["term Motet"])
    end
  end
end
