class Nullify < ActiveRecord::Migration[4.2]
  def self.up
    # Make some values NULLable so import works
    execute("ALTER TABLE people MODIFY full_name VARCHAR(255) null;")
    
  end

  def self.down
    # No recovery from this
  end
end