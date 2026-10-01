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

    it "can match an explicitly supplied rule without changing the user" do
      term = StandardTerm.new(term: "Motet")
      user = instance_double(User, get_notifications: ["standard_term term:Mass"], name: "Cataloguer")

      matcher = described_class.new(term, user, rule: "standard_term term:Motet")

      expect(matcher.get_matches).to eq(["term Motet"])
    end
  end

  describe ".get_model_for_rule" do
    it "returns the model declared by the supplied rule" do
      expect(described_class.get_model_for_rule("standard_term term:Motet")).to eq(StandardTerm)
    end

    it "rejects a blank rule" do
      expect(described_class.get_model_for_rule(nil)).to be(false)
    end
  end

  describe ".valid_rule?" do
    it "accepts a supported comparison rule" do
      expect(described_class.valid_rule?(
        'source composer:"Mozart"',
        models: %w[source work institution]
      )).to be(true)
    end

    it "rejects models outside the supplied allowlist" do
      expect(described_class.valid_rule?(
        'person full_name:"Mozart"',
        models: %w[source work institution]
      )).to be(false)
    end

    it "rejects multiple rules" do
      expect(described_class.valid_rule?("source composer:Mozart\nsource title:Requiem")).to be(false)
    end
  end
end
