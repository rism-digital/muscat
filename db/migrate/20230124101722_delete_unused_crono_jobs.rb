class DeleteUnusedCronoJobs < ActiveRecord::Migration[5.2]
  def change
    drop_table :crono_jobs, if_exists: true
  end
end
