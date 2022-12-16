class MoveDataFromWorksToWorkNodes < ActiveRecord::Migration[5.2]
  def change
    execute("INSERT INTO `work_nodes` SELECT * FROM `works`;")
    execute("INSERT INTO `sources_to_work_nodes` SELECT * FROM `sources_to_works`;")
    execute("INSERT INTO `work_nodes_to_catalogues` SELECT * FROM `works_to_catalogues`;")
    execute("INSERT INTO `work_nodes_to_institutions` SELECT * FROM `works_to_institutions`;")
    execute("INSERT INTO `work_nodes_to_liturgical_feasts` SELECT * FROM `works_to_liturgical_feasts`;")
    execute("INSERT INTO `work_nodes_to_people` SELECT * FROM `works_to_people`;")
    execute("INSERT INTO `work_nodes_to_publications` SELECT * FROM `works_to_publications`;")
    execute("INSERT INTO `work_nodes_to_standard_terms` SELECT * FROM `works_to_standard_terms`;")
    execute("INSERT INTO `work_nodes_to_standard_titles` SELECT * FROM `works_to_standard_titles`;")
    execute("TRUNCATE TABLE `works`;")
    execute("TRUNCATE TABLE `sources_to_works`;")
    execute("TRUNCATE TABLE `works_to_catalogues`;")
    execute("TRUNCATE TABLE `works_to_institutions`;")
    execute("TRUNCATE TABLE `works_to_liturgical_feasts`;")
    execute("TRUNCATE TABLE `works_to_people`;")
    execute("TRUNCATE TABLE `works_to_publications`;")
    execute("TRUNCATE TABLE `works_to_standard_terms`;")
    execute("TRUNCATE TABLE `works_to_standard_titles`;")
  end
end
