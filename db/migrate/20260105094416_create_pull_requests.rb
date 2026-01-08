class CreatePullRequests < ActiveRecord::Migration[7.2]
  def change
    create_table :pull_requests do |t|
      t.string :item_type
      t.integer :item_id
      t.integer :wf_owner
      t.integer :wf_stage
      t.text :marc_source
      t.text :original_marc
      t.text :message

      t.timestamps
    end
  end
end
