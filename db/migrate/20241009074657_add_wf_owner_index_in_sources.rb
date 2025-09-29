class AddWfOwnerIndexInSources < ActiveRecord::Migration[7.1]
  def change
    add_index :sources, :wf_owner
  end
end
