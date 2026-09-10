require "rails_helper"

RSpec.describe AddToFolderJob, type: :job do
  it "adds search results page by page and indexes only newly added folder items" do
    search_page_class = Class.new do
      include Enumerable

      attr_reader :total_entries, :total_pages

      def initialize(items, total_entries:, total_pages:)
        @items = items
        @total_entries = total_entries
        @total_pages = total_pages
      end

      def each(&block)
        @items.each(&block)
      end

      def length
        @items.length
      end
    end
    first_page = search_page_class.new(
      [instance_double(Source), instance_double(Source)],
      total_entries: 3,
      total_pages: 2,
    )
    second_page = search_page_class.new(
      [instance_double(Source)],
      total_entries: 3,
      total_pages: 2,
    )

    model = class_double(Source)
    search_params = { q: { title_cont: "Mass" } }
    observed_params = []
    pages = [[first_page, nil], [second_page, nil]]
    allow(model).to receive(:search_as_ransack) do |params|
      observed_params << params.deep_dup
      pages.shift
    end

    folder_items = instance_double(ActiveRecord::Associations::CollectionProxy)
    folder = instance_double(Folder, folder_type: "Source", folder_items: folder_items)
    allow(Folder).to receive(:find).with(12).and_return(folder)
    expect(folder).to receive(:add_items)
      .with(first_page, return_item_ids: true)
      .and_return([101, 102])
    expect(folder).to receive(:add_items)
      .with(second_page, return_item_ids: true)
      .and_return([103])

    indexed_items = instance_double(ActiveRecord::Relation)
    expect(folder_items).to receive(:where)
      .with(item_type: "Source", item_id: [101, 102, 103])
      .and_return(indexed_items)
    expect(Sunspot).to receive(:index).with(indexed_items)
    expect(Sunspot).to receive(:commit).once

    job = described_class.new(12, search_params, model)
    allow(job).to receive(:update_stage)
    allow(job).to receive(:update_progress_max)
    allow(job).to receive(:update_stage_progress)

    job.perform

    expect(observed_params.map { |params| params[:page] }).to eq([nil, 2])
    expect(observed_params.map { |params| params[:per_page] }).to eq([1000, 1000])
    expect(search_params).to eq(q: { title_cont: "Mass" })
  end
end
