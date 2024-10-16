class AddIdToPublicationToStandardTerms < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `publications_to_standard_terms` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `publications_to_standard_terms` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `publication_id`, `standard_term_id`);")
  end

  def self.down
    execute("ALTER TABLE `publications_to_standard_terms` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `publications_to_standard_terms` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `publications_to_standard_terms` DROP PRIMARY KEY;")
    execute("ALTER TABLE `publications_to_standard_terms` DROP `id`")
  end
end
