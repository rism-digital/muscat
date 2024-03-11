class CreatePublicationToStandardTermRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :publications_to_standard_terms, :marc_tag, :string
    add_column :publications_to_standard_terms, :relator_code, :string
  end
end
