class CreateTokensManager < ActiveRecord::Migration[7.0]
  def change
    create_table :authorization_tokens do |t|
      t.string :name
      t.string :token
      t.string :comment
      t.boolean :active

      t.timestamps
    end
  end
end
