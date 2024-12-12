class ExtendWorkNodesToStandardTitles < ActiveRecord::Migration[7.2]
  def change
    add_column :work_nodes_to_standard_titles, :marc_tag, :string
    add_column :work_nodes_to_standard_titles, :relator_code, :string
  end
end
