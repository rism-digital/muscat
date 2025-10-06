class ExtendSourcesToWorkNodes < ActiveRecord::Migration[7.2]
  def change
    add_column :sources_to_work_nodes, :marc_tag, :string
    add_column :sources_to_work_nodes, :relator_code, :string
  end
end
