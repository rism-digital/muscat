class ChangeCatalogueToPublication < ActiveRecord::Migration[5.2]
  def change
    rename_table :catalogues, :publications
    rename_table :catalogues_to_catalogues, :publications_to_publications
    rename_table :catalogues_to_institutions, :publications_to_institutions
    rename_table :catalogues_to_people, :publications_to_people
    rename_table :catalogues_to_places, :publications_to_places
    rename_table :catalogues_to_standard_terms, :publications_to_standard_terms

    rename_table :holdings_to_catalogues, :holdings_to_publications
    rename_table :institutions_to_catalogues, :institutions_to_publications
    rename_table :people_to_catalogues, :people_to_publications
    rename_table :sources_to_catalogues, :sources_to_publications
    rename_table :works_to_catalogues, :works_to_publications

    rename_column :publications_to_publications, :catalogue_a_id, :publication_a_id
    rename_column :publications_to_publications, :catalogue_b_id, :publication_b_id

    rename_column :publications_to_institutions, :catalogue_id, :publication_id
    rename_column :publications_to_people, :catalogue_id, :publication_id
    rename_column :publications_to_places, :catalogue_id, :publication_id
    rename_column :publications_to_standard_terms, :catalogue_id, :publication_id
    
    rename_column :holdings_to_publications, :catalogue_id, :publication_id
    rename_column :institutions_to_publications, :catalogue_id, :publication_id
    rename_column :people_to_publications, :catalogue_id, :publication_id
    rename_column :sources_to_publications, :catalogue_id, :publication_id
    rename_column :works_to_publications, :catalogue_id, :publication_id
  end
end
