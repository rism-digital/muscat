class CreateSourcesToLiturgicalFeastsRelation < ActiveRecord::Migration[7.0]
  def change
    add_column :sources_to_liturgical_feasts, :marc_tag, :string
    add_column :sources_to_liturgical_feasts, :relator_code, :string
  end
end
