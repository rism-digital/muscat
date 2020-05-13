class AddRemoteToDelayedJobs < ActiveRecord::Migration[4.2]
  def change
    change_table :delayed_jobs do |t|
      t.string :parent_type
      t.integer :parent_id
    end
  end
end