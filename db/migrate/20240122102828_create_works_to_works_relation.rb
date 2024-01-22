class CreateWorksToWorksRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_works, :marc_tag, :string
    add_column :works_to_works, :relator_code, :string
  end
end

