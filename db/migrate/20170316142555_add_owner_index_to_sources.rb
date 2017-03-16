class AddOwnerIndexToSources < ActiveRecord::Migration
  def change
    add_index :sources, :wf_owner
  end
end
