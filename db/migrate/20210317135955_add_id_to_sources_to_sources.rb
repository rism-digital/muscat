class AddIdToSourcesToSources < ActiveRecord::Migration[5.2]
  def self.up
    execute("ALTER TABLE `sources_to_sources` ADD `id` INT")
    execute("ALTER TABLE `sources_to_sources` MODIFY COLUMN `id` INT NOT NULL UNIQUE AUTO_INCREMENT FIRST;")
    execute("ALTER TABLE `sources_to_sources` ADD PRIMARY KEY (`id`)");
    execute("ALTER TABLE `sources_to_sources` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `source_a_id`, `source_b_id`);")
    execute("UPDATE sources_to_sources SET marc_tag = 775;")
  end

  def self.down
    execute("ALTER TABLE `sources_to_sources` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `sources_to_sources` DROP PRIMARY KEY;")
    execute("ALTER TABLE `sources_to_sources` DROP `id`;")
  end
end
