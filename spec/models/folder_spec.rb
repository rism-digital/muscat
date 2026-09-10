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

  describe "#add_items" do
    it "returns new item IDs and retains progress reporting" do
      folder = described_class.allocate
      items = Array.new(51) do |index|
        Source.allocate.tap { |item| allow(item).to receive(:id).and_return(index + 1) }
      end
      folder_items = instance_double(ActiveRecord::Associations::CollectionProxy)
      existing_items = instance_double(ActiveRecord::Relation)

      allow(folder).to receive_messages(id: 10, folder_type: "Source", folder_items: folder_items)
      allow(folder_items).to receive(:where).and_return(existing_items)
      allow(existing_items).to receive(:pluck).with(:item_id).and_return([])
      allow(FolderItem).to receive(:new) do |attributes|
        instance_double(FolderItem, item_id: attributes[:item].id)
      end
      allow(FolderItem).to receive(:import)

      progress = []
      added_ids = folder.add_items(items, return_item_ids: true) { |count| progress << count }

      expect(added_ids).to eq((1..51).to_a)
      expect(progress).to eq([0, 50])
    end
  end
end
