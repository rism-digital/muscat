class ExtendWorkNodesToInstitutions < ActiveRecord::Migration[7.2]
  def change
    add_column :work_nodes_to_institutions, :marc_tag, :string
    add_column :work_nodes_to_institutions, :relator_code, :string
  end
end
