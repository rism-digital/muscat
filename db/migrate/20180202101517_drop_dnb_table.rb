class DropDnbTable < ActiveRecord::Migration[4.2]
  def change
    drop_table :DNB if ActiveRecord::Base.connection.table_exists? 'DNB' do |t|
      t.integer "id",     limit: 4,     default: 0, null: false
      t.text    "ext_id", limit: 65535
    end
    drop_table :VIAF if ActiveRecord::Base.connection.table_exists? 'VIAF' do |t|
      t.integer "id",     limit: 4,     default: 0, null: false
      t.text    "ext_id", limit: 65535
    end
  end
end
