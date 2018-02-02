class DropDnbTable < ActiveRecord::Migration
  def change
    drop_table :DNB do |t|
      t.integer "id",     limit: 4,     default: 0, null: false
      t.text    "ext_id", limit: 65535
    end
    drop_table :VIAF do |t|
      t.integer "id",     limit: 4,     default: 0, null: false
      t.text    "ext_id", limit: 65535
    end
  end
end
