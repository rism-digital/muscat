class AddIdToWorksToPlaces < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `works_to_places` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `works_to_places` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `work_id`, `place_id`);")
  end

  def self.down
    execute("ALTER TABLE `works_to_places` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `works_to_places` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `works_to_places` DROP PRIMARY KEY;")
    execute("ALTER TABLE `works_to_places` DROP `id`")
  end
end

