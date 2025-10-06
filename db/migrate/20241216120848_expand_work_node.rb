class ExpandWorkNode < ActiveRecord::Migration[7.2]
  def change
    add_column :work_nodes, :ext_number, :string
    add_column :work_nodes, :ext_code, :string
  end
end
