class AddIdToHoldingsToPublications < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `holdings_to_publications` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `holdings_to_publications` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `holding_id`, `publication_id`);")
  end

  def self.down
    execute("ALTER TABLE `holdings_to_publications` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `holdings_to_publications` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `holdings_to_publications` DROP PRIMARY KEY;")
    execute("ALTER TABLE `holdings_to_publications` DROP `id`")
  end
end
