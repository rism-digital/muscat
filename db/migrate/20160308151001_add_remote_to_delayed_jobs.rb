class AddRemoteToDelayedJobs < ActiveRecord::Migration
  def change
    change_table :delayed_jobs do |t|
      t.string :parent_type
      t.integer :parent_id
    end
  end
end