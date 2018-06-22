class AddSubTopicToStandardTerms < ActiveRecord::Migration[4.2]
  def change    
    rename_column :standard_titles, :variants, :alternate_terms
    add_column :standard_titles, :sub_topic, :text
    add_column :standard_titles, :viaf, :string
    add_column :standard_titles, :gnd, :string
    add_column :standard_titles, :latin, :boolean
 
    add_column :standard_terms, :sub_topic, :text
    add_column :standard_terms, :viaf, :string
    add_column :standard_terms, :gnd, :string
    
    add_column :places, :viaf, :string
    add_column :places, :gnd, :string
    
    add_column :liturgical_feasts, :sub_topic, :text
    add_column :liturgical_feasts, :viaf, :string
    add_column :liturgical_feasts, :gnd, :string
  end
end
