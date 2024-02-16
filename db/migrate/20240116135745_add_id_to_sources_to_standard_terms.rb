class AddIdToSourcesToStandardTerms < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `sources_to_standard_terms` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `sources_to_standard_terms` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `standard_term_id`, `source_id`);")
  end

  def self.down
    execute("ALTER TABLE `sources_to_standard_terms` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `sources_to_standard_terms` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `sources_to_standard_terms` DROP PRIMARY KEY;")
    execute("ALTER TABLE `sources_to_standard_terms` DROP `id`")
  end
end
