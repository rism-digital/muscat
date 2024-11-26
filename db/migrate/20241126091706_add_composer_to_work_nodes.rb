class AddComposerToWorkNodes < ActiveRecord::Migration[7.1]
  def change
    add_column :work_nodes, :composer, :string
  end
end
