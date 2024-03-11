class AddIdToPublicationToPublication < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `publications_to_publications` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `publications_to_publications` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `publication_a_id`, `publication_b_id`);")
  end

  def self.down
    execute("ALTER TABLE `publications_to_publications` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `publications_to_publications` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `publications_to_publications` DROP PRIMARY KEY;")
    execute("ALTER TABLE `publications_to_publications` DROP `id`")
  end
end
