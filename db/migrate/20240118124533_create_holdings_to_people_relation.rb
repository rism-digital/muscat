class CreateHoldingsToPeopleRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :holdings_to_people, :marc_tag, :string
    add_column :holdings_to_people, :relator_code, :string
  end
end
