class CreateSourcesToPublicationsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :sources_to_publications, :marc_tag, :string
    add_column :sources_to_publications, :relator_code, :string
  end
end
