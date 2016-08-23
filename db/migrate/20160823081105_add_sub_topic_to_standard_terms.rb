class AddSubTopicToStandardTerms < ActiveRecord::Migration
  def change
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
