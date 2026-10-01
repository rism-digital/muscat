# Utilities for Source documents left in Solr after database-only deletions.
class SourceIndex
  Tombstone = Struct.new(:id)

  def self.with_tombstones(results, hits)
    records = results.index_by { |source| source.id.to_s }
    results.dup.replace(hits.map { |hit| records[hit.primary_key.to_s] || Tombstone.new(hit.primary_key) })
  end

  # In the Rails console:
  #   SourceIndex.count_missing  # count missing records without changing Solr
  #   SourceIndex.purge_missing! # remove them and commit
  def self.count_missing(batch_size: 1000)
    purge_missing!(batch_size: batch_size, dry_run: true)
  end

  # Returns the number of missing records. Never deletes database records.
  def self.purge_missing!(batch_size: 1000, dry_run: false)
    unless batch_size.is_a?(Integer) && batch_size.positive?
      raise ArgumentError, "batch_size must be a positive integer"
    end

    cursor = '*'
    missing_count = 0

    loop do
      # Cursor pagination remains stable even if Solr auto-commits deletions
      # while we scan. Only fetch IDs, without loading MARC records.
      search = Source.solr_search do
        paginate per_page: batch_size, cursor: cursor
        adjust_solr_params { |params| params[:fl] = 'id' }
      end
      hits = search.hits
      break if hits.empty?

      ids = hits.map(&:primary_key)
      existing_ids = Source.unscoped.where(id: ids).pluck(:id).map(&:to_s)
      missing_ids = ids - existing_ids
      missing_count += missing_ids.size
      Sunspot.remove_by_id(Source, *missing_ids) if !dry_run && missing_ids.any?

      next_cursor = hits.next_page_cursor
      break if next_cursor == cursor

      cursor = next_cursor
    end

    Sunspot.commit if !dry_run && missing_count.positive?
    missing_count
  end
end
