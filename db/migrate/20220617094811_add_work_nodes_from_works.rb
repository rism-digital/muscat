class AddWorkNodesFromWorks < ActiveRecord::Migration[5.2]
  def change
    execute("CREATE TABLE `work_nodes` LIKE `works`;")
    execute("CREATE TABLE `sources_to_work_nodes` LIKE `sources_to_works`;")
    execute("CREATE TABLE `work_nodes_to_catalogues` LIKE `works_to_catalogues`;")
    execute("CREATE TABLE `work_nodes_to_institutions` LIKE `works_to_institutions`;")
    execute("CREATE TABLE `work_nodes_to_liturgical_feasts` LIKE `works_to_liturgical_feasts`;")
    execute("CREATE TABLE `work_nodes_to_people` LIKE `works_to_people`;")
    execute("CREATE TABLE `work_nodes_to_publications` LIKE `works_to_publications`;")
    execute("CREATE TABLE `work_nodes_to_standard_terms` LIKE `works_to_standard_terms`;")
    execute("CREATE TABLE `work_nodes_to_standard_titles` LIKE `works_to_standard_titles`;")
  end
end
