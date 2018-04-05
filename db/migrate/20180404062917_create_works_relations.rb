class CreateWorksRelations < ActiveRecord::Migration
  def change
    create_table :works_to_catalogues do |t|
      t.column :work_id, :integer 
      t.column :catalogue_id, :integer
    end
    create_table :works_to_standard_terms do |t|
      t.column :work_id, :integer 
      t.column :standard_term_id, :integer
    end
    create_table :works_to_standard_titles do |t|
      t.column :work_id, :integer 
      t.column :standard_title_id, :integer
    end

    add_index :works_to_catalogues, :work_id
    add_index :works_to_catalogues, :catalogue_id

    add_index :works_to_standard_terms, :work_id
    add_index :works_to_standard_terms, :standard_term_id

    add_index :works_to_standard_titles, :work_id
    add_index :works_to_standard_titles, :standard_title_id

  end
end
