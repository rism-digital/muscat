# Run without spec_helper to avoid touching the configured database/Solr core:
# bundle exec rspec --options /dev/null spec/lib/source_index_spec.rb
require 'rspec/mocks'
require 'rspec/mocks/matchers/receive'
require 'active_support/all'
require 'sunspot'
require_relative '../../lib/source_index'

RSpec.describe SourceIndex do
  def hit(id)
    double(primary_key: id.to_s)
  end

  describe '.with_tombstones' do
    it 'preserves hit order and pagination when live and missing records are mixed' do
      source = double(id: 2)
      results = Sunspot::Search::PaginatedCollection.new([source], 3, 3, 10)
      rows = described_class.with_tombstones(results, [hit(1), hit(2), hit(3)])

      expect(rows.map(&:id)).to eq(['1', 2, '3'])
      expect(rows[1]).to equal(source)
      expect(rows.first).to be_a(SourceIndex::Tombstone)
      expect([rows.current_page, rows.per_page, rows.total_entries]).to eq([3, 3, 10])
      expect(results).to eq([source])
    end

    it 'displays a page made entirely of missing records' do
      results = Sunspot::Search::PaginatedCollection.new([], 1, 30, 2)
      rows = described_class.with_tombstones(results, [hit(1), hit(2)])

      expect(rows.map(&:id)).to eq(['1', '2'])
      expect(rows.total_entries).to eq(2)
    end

    it 'keeps a truly empty search empty' do
      results = Sunspot::Search::PaginatedCollection.new([], 1, 30, 0)
      expect(described_class.with_tombstones(results, [])).to be_empty
    end
  end

  describe '.purge_missing!' do
    before do
      stub_const('Source', double('Source'))
      allow(Source).to receive(:unscoped).and_return(double('Unscoped source relation'))
    end

    def batch(ids, cursor, next_cursor, existing_ids)
      hits = Sunspot::Search::CursorPaginatedCollection.new(ids.map { |id| hit(id) }, 2, 4, cursor, next_cursor)
      query = double('Sunspot query')
      expect(query).to receive(:paginate).with(per_page: 2, cursor: cursor)
      expect(query).to receive(:adjust_solr_params) do |&block|
        params = {}
        block.call(params)
        expect(params).to eq(fl: 'id')
      end
      expect(Source).to receive(:solr_search).ordered do |&block|
        query.instance_eval(&block)
        double(hits: hits)
      end
      if ids.any?
        expect(Source.unscoped).to receive(:where).with(id: ids.map(&:to_s))
          .and_return(double(pluck: existing_ids))
      end
    end

    it 'scans every cursor batch, removes only missing IDs, and commits' do
      batch([1, 2], '*', 'cursor-1', [2])
      batch([3, 4], 'cursor-1', 'cursor-2', [4])
      batch([], 'cursor-2', 'cursor-2', [])
      expect(Sunspot).to receive(:remove_by_id).with(Source, '1')
      expect(Sunspot).to receive(:remove_by_id).with(Source, '3')
      expect(Sunspot).to receive(:commit)

      expect(described_class.purge_missing!(batch_size: 2)).to eq(2)
    end

    it 'counts missing IDs without changing Solr in dry-run mode' do
      batch([1, 2], '*', 'cursor-1', [2])
      batch([], 'cursor-1', 'cursor-1', [])
      expect(Sunspot).not_to receive(:remove_by_id)
      expect(Sunspot).not_to receive(:commit)

      expect(described_class.purge_missing!(batch_size: 2, dry_run: true)).to eq(1)
    end

    it 'returns the orphan count through count_missing without changing Solr' do
      batch([1, 2], '*', 'cursor-1', [2])
      batch([3, 4], 'cursor-1', 'cursor-2', [4])
      batch([], 'cursor-2', 'cursor-2', [])
      expect(Sunspot).not_to receive(:remove_by_id)
      expect(Sunspot).not_to receive(:commit)

      expect(described_class.count_missing(batch_size: 2)).to eq(2)
    end

    it 'does not commit or delete when the index has no missing records' do
      batch([1, 2], '*', 'cursor-1', [1, 2])
      batch([], 'cursor-1', 'cursor-1', [])
      expect(Sunspot).not_to receive(:remove_by_id)
      expect(Sunspot).not_to receive(:commit)

      expect(described_class.purge_missing!(batch_size: 2)).to eq(0)
    end

    it 'rejects invalid batch sizes before querying Solr' do
      expect(Source).not_to receive(:solr_search)
      expect { described_class.purge_missing!(batch_size: 0) }.to raise_error(ArgumentError)
    end
  end
end
