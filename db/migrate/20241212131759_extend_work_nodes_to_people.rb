class ExtendWorkNodesToPeople < ActiveRecord::Migration[7.2]
  def change
    add_column :work_nodes_to_people, :marc_tag, :string
    add_column :work_nodes_to_people, :relator_code, :string
  end
end
