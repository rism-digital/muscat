class CreateWorksToStandardTermsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_standard_terms, :marc_tag, :string
    add_column :works_to_standard_terms, :relator_code, :string
  end
end

