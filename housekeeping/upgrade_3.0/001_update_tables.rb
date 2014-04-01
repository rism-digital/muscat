class UpdateTables < ActiveRecord::Migration

@drop_tables = 
  [:configurations, :do_div_files, :do_divs, :do_file_groups, :do_files, :do_images, :do_items, 
    :editor_profiles, :folders, :jobs, :menu_items, :pages, :users, :folder_items, 
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
  [:catalogues, :libraries, :liturgical_feasts, :people, :places, 
  :standard_terms, :standard_titles, :work_incipits, :works]

@update_tables =   
  [:catalogues, :libraries, :liturgical_feasts, :people, :places, 
  :standard_terms, :standard_titles,, :works]

def self.up
  
  @drop_tables.each do |t|
    execute "DROP TABLE IF EXISTS #{t}";
  end
  
  # Update schema for sources/manuscripts
  execute "RENAME TABLE manuscripts TO sources"
  execute "ALTER TABLE sources CHANGE ext_id ext_id INT(11) NOT NULL;"
  execute "ALTER TABLE sources CHANGE ms_title title VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE ms_title_d title_d VARCHAR(128)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE ms_no shelf_mark VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE ms_lib_siglums lib_siglum VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  # Rename columns is works
  execute "ALTER TABLE work_incipits CHANGE instrument_or_voice instrument_voice VARCHAR(255)  NULL  DEFAULT NULL"
  execute "ALTER TABLE work_incipits CHANGE key_or_mode key_mode VARCHAR(255)  NULL  DEFAULT NULL"
  
  # Rename ms_count
  @rename_mscount_tables.each do |t|
    execute "ALTER TABLE #{t} CHANGE ms_count src_count INT(11) NULL DEFAULT 0"
  end
  
  # Rename relation tables
  execute "RENAME TABLE catalogues_manuscripts TO catalogues_sources"
  execute "ALTER TABLE catalogues_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE institutions_manuscripts TO institutions_sources"
  execute "ALTER TABLE institutions_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE libraries_manuscripts TO libraries_sources"
  execute "ALTER TABLE libraries_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE liturgical_feasts_manuscripts TO liturgical_feasts_sources"
  execute "ALTER TABLE liturgical_feasts_sources CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_people TO sources_people"
  execute "ALTER TABLE sources_people CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
  execute "RENAME TABLE manuscripts_places TO sources_places"
  execute "ALTER TABLE sources_places CHANGE manuscript_id source_id INT(11)  NULL  DEFAULT NULL"
  
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
  execute "ALTER TABLE sources_people ADD CONSTRAINT sources_people_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_places ADD CONSTRAINT sources_places_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_terms ADD CONSTRAINT sources_standard_terms_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_titles ADD CONSTRAINT sources_standard_titles_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_works ADD CONSTRAINT sources_works_fk1 FOREIGN KEY (source_id) REFERENCES sources (id) ON UPDATE CASCADE"

  execute "ALTER TABLE libraries_sources ADD CONSTRAINT libraries_sources_fk2 FOREIGN KEY (library_id) REFERENCES libraries (id) ON UPDATE CASCADE"
  execute "ALTER TABLE institutions_sources ADD CONSTRAINT institutions_sources_fk2 FOREIGN KEY (institution_id) REFERENCES institutions (id) ON UPDATE CASCADE"
  execute "ALTER TABLE catalogues_sources ADD CONSTRAINT catalogues_sources_fk2 FOREIGN KEY (catalogue_id) REFERENCES catalogues (id) ON UPDATE CASCADE"
  execute "ALTER TABLE liturgical_feasts_sources ADD CONSTRAINT liturgical_feasts_sources_fk2 FOREIGN KEY (liturgical_feast_id) REFERENCES liturgical_feasts (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_people ADD CONSTRAINT sources_people_fk2 FOREIGN KEY (person_id) REFERENCES people (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_places ADD CONSTRAINT sources_places_fk2 FOREIGN KEY (place_id) REFERENCES places (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_terms ADD CONSTRAINT sources_standard_terms_fk2 FOREIGN KEY (standard_term_id) REFERENCES standard_terms (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_standard_titles ADD CONSTRAINT sources_standard_titles_fk2 FOREIGN KEY (standard_title_id) REFERENCES standard_titles (id) ON UPDATE CASCADE"
  execute "ALTER TABLE sources_works ADD CONSTRAINT sources_works_fk2 FOREIGN KEY (work_id) REFERENCES works (id) ON UPDATE CASCADE"

  execute "ALTER TABLE work_incipits ADD CONSTRAINT work_incipits_fk1 FOREIGN KEY (work_id) REFERENCES works (id) ON UPDATE CASCADE"
  
  # update source_id in sources
  execute "UPDATE sources s, (SELECT DISTINCT id, ext_id FROM sources) t1 SET s.source_id = t1.ext_id WHERE s.source_id = t1.id;"
  
  @update_tables.each do |t|
    execute "UPDATE #{t} SET id = id + 100000000" # WE CAN HAVE LOW EXT_IDs
    execute "UPDATE #{t} SET id = ext_id"
    execute "ALTER TABLE #{t} DROP COLUMN ext_id"
  end 
  
#/* 13:12:57 root@localhost */ ALTER TABLE `catalogues` CHANGE `ms_count` `source_count` INT(11)  NULL  DEFAULT '0';
  
  
end

end

UpdateTables.up