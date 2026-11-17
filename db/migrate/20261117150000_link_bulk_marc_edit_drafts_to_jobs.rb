class LinkBulkMarcEditDraftsToJobs < ActiveRecord::Migration[7.2]
  def up
    add_column :bulk_marc_edit_drafts, :delayed_job_id, :bigint
    add_index :bulk_marc_edit_drafts, :delayed_job_id

    link_existing_jobs
  end

  def down
    remove_column :bulk_marc_edit_drafts, :delayed_job_id
  end

  private

  def link_existing_jobs
    # Preserve previews for jobs already queued before this association existed.
    # Read only the root scalar ID; do not deserialize executable job payloads
    # or depend on application model code during a migration.
    jobs = connection.select_rows("SELECT id, handler FROM delayed_jobs WHERE handler LIKE '%!ruby/object:BulkMarcEditorJob%'")
    jobs.each do |job_id, handler|
      next unless handler.start_with?("--- !ruby/object:BulkMarcEditorJob\n")

      draft_id = handler[/^preview_draft_id: (\d+)$/, 1]
      next unless draft_id

      execute <<~SQL
        UPDATE bulk_marc_edit_drafts
        SET delayed_job_id = #{connection.quote(job_id)}
        WHERE id = #{connection.quote(draft_id)}
          AND confirmed_at IS NOT NULL AND delayed_job_id IS NULL
      SQL
    end
  end
end
