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

  describe "#publication_status" do
    let(:folder) { described_class.create!(name: "Status", folder_type: "Source", user: create(:admin)) }

    it "fails closed for unsupported stored folder types" do
      folder = described_class.new(name: "Bad", folder_type: "sources ON 1=1 --")

      expect(folder.publication_status).to be_nil
    end

    it "has no publication status for models without workflow state" do
      folder = described_class.new(name: "Users", folder_type: "User")

      expect(folder.publication_status).to be_nil
    end

    it "has no publication status for an empty folder" do
      expect(folder.publication_status).to be_nil
    end

    { [1, 1] => :published, [0, 0] => :inprogress, [1, 0] => :mixed,
      [1, 1, 0] => :mixed, [0, 0, 1] => :mixed, [2, 3] => nil,
      [1, 2, 3] => :published, [0, 2, 3] => :inprogress }.each do |stages, expected|
      it "summarizes source states #{stages.inspect} as #{expected.inspect}" do
        stages.each_with_index do |stage, index|
          folder.add_item(create(:source, id: index + 1, wf_stage: stage))
        end

        expect(folder.publication_status).to eq(expected)
      end
    end

    it "ignores missing records and mismatched polymorphic types" do
      source = create(:source, wf_stage: :published)
      folder.add_item(source)
      folder.folder_items.create!(item_type: "Source", item_id: 999999)
      other = create(:source, id: 2, wf_stage: :inprogress)
      folder.folder_items.create!(item_type: "Person", item_id: other.id)

      expect(folder.publication_status).to eq(:published)
    end

    it "recognizes the legacy unpublished enum value for holdings" do
      folder.update!(folder_type: "Holding")
      source = create(:source)
      folder.add_item(create(:holding, source: source, wf_stage: :unpublished))
      expect(folder.publication_status).to eq(:inprogress)

      folder.add_item(create(:holding, source: source, wf_stage: :published))
      expect(folder.publication_status).to eq(:mixed)
    end

    it "ignores unset holding statuses" do
      folder.update!(folder_type: "Holding")
      folder.add_item(create(:holding, source: create(:source), wf_stage: nil))

      expect(folder.publication_status).to be_nil
    end

    it "summarizes work folders" do
      folder.update!(folder_type: "Work")
      folder.add_item(create(:work))

      expect(folder.publication_status).to eq(:published)
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

  describe "#add_item" do
    it "creates the join record without retaining it in the folder association" do
      folder = described_class.allocate
      item = Source.allocate

      allow(folder).to receive_messages(id: 10, folder_type: "Source", has_item?: false)
      allow(item).to receive(:id).and_return(42)

      expect(folder).not_to receive(:folder_items)
      expect(FolderItem).to receive(:create).with(folder_id: 10, item_id: 42, item_type: "Source")

      expect(folder.add_item(item)).to eq(true)
    end
  end
end
