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

  describe "#reset_expiration!" do
    it "extends the expiration date by six months" do
      folder = described_class.create!(name: "Sources", folder_type: "Source", user: create(:user))
      previous_expiration = folder.delete_date

      travel 1.day do
        folder.reset_expiration!

        expect(folder.reload.delete_date).to be_within(1.second).of(6.months.from_now)
        expect(folder.delete_date).to be > previous_expiration
      end
    end
  end
end
