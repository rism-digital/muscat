class AddIdToSourcesToWorks < ActiveRecord::Migration[5.2]
  def self.up
    execute("ALTER TABLE `sources_to_works` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `sources_to_works` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `source_id`, `work_id`);")
  end

  def self.down
    execute("ALTER TABLE `sources_to_works` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `sources_to_works` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `sources_to_works` DROP PRIMARY KEY;")
    execute("ALTER TABLE `sources_to_works` DROP `id`;")
  end
end
