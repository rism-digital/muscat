class RemoveSrcCount < ActiveRecord::Migration[4.2]
  def change
    remove_column :people, :src_count, :integer
		remove_column :standard_terms, :src_count, :integer
		remove_column :standard_titles, :src_count, :integer
		remove_column :works, :src_count, :integer
		remove_column :work_incipits, :src_count, :integer
		remove_column :liturgical_feasts, :src_count, :integer
		remove_column :places, :src_count, :integer
		remove_column :institutions, :src_count, :integer
  end
end
