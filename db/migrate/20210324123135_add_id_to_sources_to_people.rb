class AddIdToSourcesToPeople < ActiveRecord::Migration[5.2]
  def self.up
    execute("ALTER TABLE `sources_to_people` ADD `id` INT")
    execute("ALTER TABLE `sources_to_people` MODIFY COLUMN `id` INT NOT NULL UNIQUE AUTO_INCREMENT FIRST;")
    execute("ALTER TABLE `sources_to_people` ADD PRIMARY KEY (`id`)");
    execute("ALTER TABLE `sources_to_people` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `source_id`, `person_id`);")
  end

  def self.down
    execute("ALTER TABLE `sources_to_people` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `sources_to_people` DROP PRIMARY KEY;")
    execute("ALTER TABLE `sources_to_people` DROP `id`;")
  end
end
