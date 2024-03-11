class AddIdToWorksToLiturgicalFeasts < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `works_to_liturgical_feasts` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `works_to_liturgical_feasts` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `work_id`, `liturgical_feast_id`);")
  end

  def self.down
    execute("ALTER TABLE `works_to_liturgical_feasts` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `works_to_liturgical_feasts` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `works_to_liturgical_feasts` DROP PRIMARY KEY;")
    execute("ALTER TABLE `works_to_liturgical_feasts` DROP `id`")
  end
end

