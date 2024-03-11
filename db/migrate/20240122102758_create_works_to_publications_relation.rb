class CreateWorksToPublicationsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_publications, :marc_tag, :string
    add_column :works_to_publications, :relator_code, :string
  end
end

