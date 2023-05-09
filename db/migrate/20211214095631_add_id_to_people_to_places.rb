class AddIdToPeopleToPlaces < ActiveRecord::Migration[5.2]
  def self.up
    execute("ALTER TABLE `people_to_places` ADD `id` BIGINT UNSIGNED NOT NULL PRIMARY KEY AUTO_INCREMENT FIRST")
    execute("ALTER TABLE `people_to_places` ADD UNIQUE INDEX `unique_records_people_to_places` (`marc_tag`, `relator_code`, `person_id`, `place_id`);")
  end

  def self.down
    execute("ALTER TABLE `people_to_places` DROP INDEX `unique_records_people_to_places`;")
    execute("ALTER TABLE `people_to_places` CHANGE `id` `id` BIGINT  UNSIGNED  NOT NULL;")
    execute("ALTER TABLE `people_to_places` DROP PRIMARY KEY;")
    execute("ALTER TABLE `people_to_places` DROP `id`;")
  end
end
