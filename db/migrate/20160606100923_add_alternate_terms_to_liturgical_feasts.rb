class AddAlternateTermsToLiturgicalFeasts < ActiveRecord::Migration[4.2]
  def change
    add_column :liturgical_feasts, :alternate_terms, :text
  end
end
