class AddAbstractToLiturgicalFeasts < ActiveRecord::Migration[5.1]
  def change
    add_column :liturgical_feasts, :abstract, :boolean
  end
end
