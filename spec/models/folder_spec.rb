require "rails_helper"

RSpec.describe Folder do
  describe "folder_type validation" do
    it "allows configured folderable model names" do
      folder = described_class.new(name: "Sources", folder_type: "Source", user: build(:user))

      expect(folder).to be_valid
    end

    it "rejects arbitrary SQL fragments" do
      folder = described_class.new(name: "Bad", folder_type: "sources ON 1=1 --", user: build(:user))

      expect(folder).not_to be_valid
      expect(folder.errors[:folder_type]).not_to be_empty
    end
  end

  describe "#is_published?" do
    it "fails closed for unsupported stored folder types" do
      folder = described_class.new(name: "Bad", folder_type: "sources ON 1=1 --")
      result = nil

      expect { result = folder.is_published? }.not_to raise_error
      expect(result).to eq(false)
    end

    it "treats folderable models without workflow state as published" do
      folder = described_class.new(name: "Users", folder_type: "User")

      expect(folder.is_published?).to eq(true)
    end
  end
end
