class DeleteCronoJobs < ActiveRecord::Migration[5.2]
  def change
    drop_table :crono_jobs
  end
end
