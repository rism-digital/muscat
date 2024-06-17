class AddIdToWorksToWorks < ActiveRecord::Migration[7.0]
  def self.up
    execute("ALTER TABLE `works_to_works` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `works_to_works` ADD UNIQUE INDEX `unique_records` (`marc_tag`, `relator_code`, `work_a_id`, `work_b_id`);")
  end

  def self.down
    execute("ALTER TABLE `works_to_works` DROP INDEX `unique_records`;")
    execute("ALTER TABLE `works_to_works` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `works_to_works` DROP PRIMARY KEY;")
    execute("ALTER TABLE `works_to_works` DROP `id`")
  end
end

