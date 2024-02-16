class CreatePersonToPublicationRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :people_to_publications, :marc_tag, :string
    add_column :people_to_publications, :relator_code, :string
  end
end
