class AddIdToSourcesToSources < ActiveRecord::Migration[5.2]
  def self.up
    execute("ALTER TABLE `sources_to_sources` ADD `id` INT")
    execute("ALTER TABLE `sources_to_sources` MODIFY COLUMN `id` INT NOT NULL UNIQUE AUTO_INCREMENT FIRST;")
    execute("ALTER TABLE `sources_to_sources` ADD PRIMARY KEY (`id`)");
  end

  def self.down
    execute("ALTER TABLE `sources_to_sources` DROP PRIMARY KEY;")
    execute("ALTER TABLE `sources_to_sources` DROP `id`;")
  end
end
