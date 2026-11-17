namespace :bulk_marc do
  desc "List all bulk MARC preview drafts and their job status"
  task list_previews: :environment do
    count = 0
    now = Time.current
    puts %w[ID STATUS FOLDER USER JOB RECORDS SAMPLE CREATED EXPIRES].join("\t")
    BulkMarcEditDraft.find_in_batches do |drafts|
      folders = Folder.where(id: drafts.map(&:folder_id)).pluck(:id, :name).to_h
      users = User.where(id: drafts.map(&:requesting_user_id)).pluck(:id, :name).to_h
      jobs = Delayed::Job.where(id: drafts.map(&:delayed_job_id).compact).index_by(&:id)
      drafts.each do |draft|
        job = jobs[draft.delayed_job_id]
        status = if draft.confirmed_at
          if !job
            "orphaned"
          elsif job.failed_at
            "failed"
          elsif job.locked_at
            "running"
          else
            "queued"
          end
        elsif !folders.key?(draft.folder_id) || !users.key?(draft.requesting_user_id)
          "orphaned"
        else
          draft.expires_at <= now ? "expired" : "pending"
        end
        values = [draft.id, status,
          "#{draft.folder_id}: #{folders.fetch(draft.folder_id, '(deleted)')}",
          "#{draft.requesting_user_id}: #{users.fetch(draft.requesting_user_id, '(deleted)')}",
          draft.delayed_job_id || "-", draft.target_count, draft.sample_size,
          draft.created_at.iso8601, draft.expires_at.iso8601]
        puts values.map { |value| value.to_s.gsub(/[\t\r\n]/, " ") }.join("\t")
        count += 1
      end
    end
    puts "#{count} preview(s)"
  end

  desc "Delete abandoned and orphaned bulk MARC preview drafts"
  task cleanup_previews: :environment do
    puts "Deleted #{BulkMarcPreviewCleanupJob.perform_now} bulk MARC preview drafts"
  end
end
