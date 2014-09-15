class UpdateTables < ActiveRecord::Migration

@drop_tables = 
  [:configurations, :editor_profiles, :folders, :jobs, 
    :menu_items, :pages, :users, :folder_items, 
    :catalogue_old_versions, 
    :institution_old_versions, 
    :library_old_versions, 
    :liturgical_feast_old_versions, 
    :person_old_versions, 
    :place_old_versions, 
    :standard_term_old_versions, 
    :standard_title_old_versions,
    :manuscript_old_versions,
    :old_versions]

@rename_mscount_tables =   
  [:catalogues, :institutions, :libraries, :liturgical_feasts, :people, :places, 
  :standard_terms, :standard_titles, :work_incipits, :works]

@update_tables =   
  [:catalogues, :institutions, :do_div_files, :do_divs, :do_file_groups, :do_files, :do_images, :do_items,
  :libraries, :liturgical_feasts, :people, :places, 
  :standard_terms, :standard_titles, :works]

def self.up
  
  @drop_tables.each do |t|
    execute "DROP TABLE IF EXISTS #{t}";
  end
  
  # Update schema for sources/manuscripts
  execute "RENAME TABLE manuscripts TO sources"
  execute "ALTER TABLE sources CHANGE ext_id ext_id INT(11) NOT NULL;"
  execute "ALTER TABLE sources CHANGE source marc_source TEXT;"
  execute "ALTER TABLE sources CHANGE ms_title title VARCHAR(256)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE ms_title_d title_d VARCHAR(256)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE ms_no shelf_mark VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE ms_lib_siglums lib_siglum VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  # Rename columns in works
  execute "ALTER TABLE work_incipits CHANGE instrument_or_voice instrument_voice VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE work_incipits CHANGE key_or_mode key_mode VARCHAR(255)  NULL  DEFAULT NULL"
  
  # Rename ms_count
  @rename_mscount_tables.each do |t|
    execute "ALTER TABLE #{t} CHANGE ms_count src_count INT(11) NULL DEFAULT 0"
  end
  
  # Add marc source columns
  execute "ALTER TABLE people ADD marc_source TEXT"
  
  # Rename relation tables
  execute "RENAME TABLE catalogues_manuscripts TO catalogues_sources"
  execute "ALTER TABLE catalogues_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE institutions_manuscripts TO institutions_sources"
  execute "ALTER TABLE institutions_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE libraries_manuscripts TO libraries_sources"
  execute "ALTER TABLE libraries_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE liturgical_feasts_manuscripts TO liturgical_feasts_sources"
  execute "ALTER TABLE liturgical_feasts_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_people TO people_sources"
  execute "ALTER TABLE people_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_places TO places_sources"
  execute "ALTER TABLE places_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_standard_terms TO sources_standard_terms"
  execute "ALTER TABLE sources_standard_terms CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_standard_titles TO sources_standard_titles"
  execute "ALTER TABLE sources_standard_titles CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_works TO sources_works"
  execute "ALTER TABLE sources_works CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "ALTER TABLE catalogues_sources ADD CONSTRAINT catalogues_manuscripts_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE institutions_sources ADD CONSTRAINT institutions_sources_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE libraries_sources ADD CONSTRAINT libraries_sources_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE liturgical_feasts_sources ADD CONSTRAINT liturgical_feasts_sources_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE people_sources ADD CONSTRAINT people_sources_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE places_sources ADD CONSTRAINT places_sources_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_terms ADD CONSTRAINT sources_standard_terms_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_titles ADD CONSTRAINT sources_standard_titles_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_works ADD CONSTRAINT sources_works_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"

  execute "ALTER TABLE libraries_sources ADD CONSTRAINT libraries_sources_fk2 FOREIGN KEY (library_id) REFERENCES libraries (id) ON UPDATE CASCADE"
  execute "ALTER TABLE institutions_sources ADD CONSTRAINT institutions_sources_fk2 FOREIGN KEY (institution_id) REFERENCES institutions (id) ON UPDATE CASCADE"
  execute "ALTER TABLE catalogues_sources ADD CONSTRAINT catalogues_sources_fk2 FOREIGN KEY (catalogue_id) REFERENCES catalogues (id) ON UPDATE CASCADE"
  execute "ALTER TABLE liturgical_feasts_sources ADD CONSTRAINT liturgical_feasts_sources_fk2 FOREIGN KEY (liturgical_feast_id) REFERENCES liturgical_feasts (id) ON UPDATE CASCADE"
  execute "ALTER TABLE people_sources ADD CONSTRAINT people_sources_fk2 FOREIGN KEY (person_id) REFERENCES people (id) ON UPDATE CASCADE"
  execute "ALTER TABLE places_sources ADD CONSTRAINT places_sources_fk2 FOREIGN KEY (place_id) REFERENCES places (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_terms ADD CONSTRAINT sources_standard_terms_fk2 FOREIGN KEY (standard_term_id) REFERENCES standard_terms (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_titles ADD CONSTRAINT sources_standard_titles_fk2 FOREIGN KEY (standard_title_id) REFERENCES standard_titles (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_works ADD CONSTRAINT sources_works_fk2 FOREIGN KEY (work_id) REFERENCES works (id) ON UPDATE CASCADE"

  # Relations for works
  execute "ALTER TABLE work_incipits ADD CONSTRAINT work_incipits_fk1 FOREIGN KEY (work_id) REFERENCES works (id) ON UPDATE CASCADE"
  
  # Fix do_divs
  execute "ALTER TABLE do_divs CHANGE do_item_id do_item_id INT(11)  NULL  DEFAULT NULL"
  
  # Relations for Digital Objects
  execute "ALTER TABLE do_div_files ADD CONSTRAINT do_file_fk1 FOREIGN KEY (do_file_id) REFERENCES do_files (id) ON UPDATE CASCADE"
  execute "ALTER TABLE do_div_files ADD CONSTRAINT do_div_fk1 FOREIGN KEY (do_div_id) REFERENCES do_divs (id) ON UPDATE CASCADE"
  execute "ALTER TABLE do_divs ADD CONSTRAINT do_item_fk1 FOREIGN KEY (do_item_id) REFERENCES do_items (id) ON UPDATE CASCADE"
  execute "ALTER TABLE do_file_groups ADD CONSTRAINT do_item_fg_fk1 FOREIGN KEY (do_item_id) REFERENCES do_items (id) ON UPDATE CASCADE"
  execute "ALTER TABLE do_files ADD CONSTRAINT do_file_group_fk1 FOREIGN KEY (do_file_group_id) REFERENCES do_file_groups (id) ON UPDATE CASCADE"
  execute "ALTER TABLE do_files ADD CONSTRAINT do_image_fk1 FOREIGN KEY (do_image_id) REFERENCES do_images (id) ON UPDATE CASCADE"
  
  # update source_id in sources
  execute "UPDATE sources s, (SELECT DISTINCT id, ext_id FROM sources) t1 SET s.source_id = t1.ext_id WHERE s.source_id = t1.id;"
  
  @update_tables.each do |t|
    execute "UPDATE #{t} SET id = id + 100000000" # WE CAN HAVE LOW EXT_IDs
    execute "UPDATE #{t} SET id = ext_id"
    execute "ALTER TABLE #{t} DROP COLUMN ext_id"
  end 
  
  # update sources
  execute "UPDATE sources SET id = id + 1000000000"
  execute "UPDATE sources SET id = CONVERT(ext_id, SIGNED INTEGER)"
  execute "ALTER TABLE sources DROP COLUMN ext_id"
  
  # Source 403011516 has a 1C char in 028, manually fix
  s = Source.find(403011516)
  s.marc_source.delete! 28.chr
  s.suppress_reindex
  s.suppress_recreate
  s.suppress_update_77x
  # Turn off partial writes or marc_record
  # will not be written, as it ignores non
  # printing chars
  ActiveRecord::Base.partial_writes = false
  s.save!
  # Turn it on as default
  ActiveRecord::Base.partial_writes = true
  
  # Quirk of the day
  # is it better to call the migration or
  # duplicate the migration code?
  require './db/migrate/20140331105619_devise_create_users.rb'
  DeviseCreateUsers.new.migrate(:up)
  
  require './db/migrate/20140331105622_create_active_admin_comments.rb'
  CreateActiveAdminComments.new.migrate(:up)
  
  require './db/migrate/20140624092937_rolify_create_roles.rb'
  RolifyCreateRoles.new.migrate(:up)
  
  require './db/migrate/20140624151537_create_searches.blacklight.rb'
  CreateSearches.new.migrate(:up)
  
  require './db/migrate/20140624151538_create_bookmarks.blacklight.rb'
  CreateBookmarks.new.migrate(:up)
  
  require './db/migrate/20140624151539_add_polymorphic_type_to_bookmarks.blacklight.rb'
  AddPolymorphicTypeToBookmarks.new.migrate(:up)
  
  # Fix the schema migration
  execute "TRUNCATE TABLE schema_migrations;"
  Dir.open('db/migrate').each do |fname|
      i = fname.split('_').first.to_i
      next if i == 0
      execute "INSERT INTO schema_migrations (version) VALUES(#{i});"
  end  
  
  # Setup the autoincrements
  ["Catalogue", "Institution", "Library", "LiturgicalFeast", "Person", "Place", "StandardTerm", "StandardTitle", "Work"].each do |classname|
    model = Kernel.const_get(classname)
    max_id = model.maximum(:id)
    max_id = max_id != nil ? max_id : 0 # WHY can't you just return 0???!
    
    # If the ids in the table already overflowed the BASE_ID use the existing id for autoincrement
    autoincrement_id = max_id < RISM::BASE_NEW_ID ? RISM::BASE_NEW_ID : max_id + 1
    
    execute "ALTER TABLE #{classname.tableize} AUTO_INCREMENT=#{RISM::BASE_NEW_ID}"
  end
  
end

end

UpdateTables.up