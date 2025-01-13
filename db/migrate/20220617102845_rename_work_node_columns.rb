class RenameWorkNodeColumns < ActiveRecord::Migration[5.2]
  def change
    execute("ALTER TABLE `sources_to_work_nodes` RENAME COLUMN work_id TO work_node_id;")
    #execute("ALTER TABLE `work_nodes_to_catalogues` RENAME COLUMN work_id TO work_node_id;")
    execute("ALTER TABLE `work_nodes_to_institutions` RENAME COLUMN work_id TO work_node_id;")
    execute("ALTER TABLE `work_nodes_to_liturgical_feasts` RENAME COLUMN work_id TO work_node_id;")
    execute("ALTER TABLE `work_nodes_to_people` RENAME COLUMN work_id TO work_node_id;")
    execute("ALTER TABLE `work_nodes_to_publications` RENAME COLUMN work_id TO work_node_id;")
    execute("ALTER TABLE `work_nodes_to_standard_terms` RENAME COLUMN work_id TO work_node_id;")
    execute("ALTER TABLE `work_nodes_to_standard_titles` RENAME COLUMN work_id TO work_node_id;")
  end
end
