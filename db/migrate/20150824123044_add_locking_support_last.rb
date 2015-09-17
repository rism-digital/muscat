# Add locking to all classes, people is already done in another migration
# It was split during development so we could migrate without reimporting
# all data back and forth.
class AddLockingSupportLast < ActiveRecord::Migration
  def change
    unless column_exists? :catalogues, :lock_version
      add_column :catalogues, :lock_version, :integer, { :default => 0, :null => false }
    end
    
    unless column_exists? :institutions, :lock_version
      add_column :institutions, :lock_version, :integer, { :default => 0, :null => false }
    end
    
    unless column_exists? :liturgical_feasts, :lock_version
      add_column :liturgical_feasts, :lock_version, :integer, { :default => 0, :null => false }
    end
        
    unless column_exists? :places, :lock_version
      add_column :places, :lock_version, :integer, { :default => 0, :null => false }
    end
    
    unless column_exists? :sources, :lock_version
      add_column :sources, :lock_version, :integer, { :default => 0, :null => false }
    end
    
    unless column_exists? :standard_terms, :lock_version
      add_column :standard_terms, :lock_version, :integer, { :default => 0, :null => false }
    end
    
    
    unless column_exists? :standard_titles, :lock_version
      add_column :standard_titles, :lock_version, :integer, { :default => 0, :null => false }
    end
    
    
  end
end
