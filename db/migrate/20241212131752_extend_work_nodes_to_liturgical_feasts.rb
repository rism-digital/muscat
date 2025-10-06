class ExtendWorkNodesToLiturgicalFeasts < ActiveRecord::Migration[7.2]
  def change
    add_column :work_nodes_to_liturgical_feasts, :marc_tag, :string
    add_column :work_nodes_to_liturgical_feasts, :relator_code, :string
  end
end
