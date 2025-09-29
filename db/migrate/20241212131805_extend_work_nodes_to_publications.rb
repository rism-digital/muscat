class ExtendWorkNodesToPublications < ActiveRecord::Migration[7.2]
  def change
    add_column :work_nodes_to_publications, :marc_tag, :string
    add_column :work_nodes_to_publications, :relator_code, :string
  end
end
