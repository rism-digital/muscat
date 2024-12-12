class AddIdToSourcesToWorkNodes < ActiveRecord::Migration[7.2]
  def self.up
    execute("ALTER TABLE `sources_to_work_nodes` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `sources_to_work_nodes` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `work_node_id`, `source_id`);")
  end

  def self.down
    execute("ALTER TABLE `sources_to_work_nodes` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `sources_to_work_nodes` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `sources_to_work_nodes` DROP PRIMARY KEY;")
    execute("ALTER TABLE `sources_to_work_nodes` DROP `id`")
  end
end
