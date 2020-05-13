class RenameRelationshipTables < ActiveRecord::Migration[4.2]
  def change
    rename_table :catalogues_sources, :sources_to_catalogues
    rename_table :institutions_sources, :sources_to_institutions
    rename_table :liturgical_feasts_sources, :sources_to_liturgical_feasts
    rename_table :people_sources, :sources_to_people
    rename_table :places_sources, :sources_to_places
    rename_table :sources_standard_terms, :sources_to_standard_terms
    rename_table :sources_standard_titles, :sources_to_standard_titles
    rename_table :sources_works, :sources_to_works
    
    rename_table :institutions_people, :people_to_institutions
  end
end
