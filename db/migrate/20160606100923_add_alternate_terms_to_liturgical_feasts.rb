class AddAlternateTermsToLiturgicalFeasts < ActiveRecord::Migration
  def change
    add_column :liturgical_feasts, :alternate_terms, :text
  end
end
