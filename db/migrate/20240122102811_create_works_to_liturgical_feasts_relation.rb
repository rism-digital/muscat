class CreateWorksToLiturgicalFeastsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :works_to_liturgical_feasts, :marc_tag, :string
    add_column :works_to_liturgical_feasts, :relator_code, :string
  end
end

