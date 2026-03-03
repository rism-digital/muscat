class CreateDelayedJobOutputs < ActiveRecord::Migration[7.2]
  def change
    create_table :delayed_job_outputs do |t|
      t.integer :delayed_job_id, null: false
      t.text :output
      t.string :status

      t.timestamps
    end
    add_index :delayed_job_outputs, :delayed_job_id
  end
end
