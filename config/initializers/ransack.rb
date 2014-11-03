# config/initializers/ransack.rb

# See documentation:
# https://github.com/activerecord-hackery/ransack/wiki/Custom-Predicates

Ransack.configure do |config|
  
  # This predicate will be intercepted in our search function
  # It will create with(FIELD, y) calls in the search
  # The ids passed in the search should be in the form of
  # field:id, eg folder_id:1 will create a with(:folder_id, 1)
  # Eg in the filter section:
  # filter :id_with_integer, as: :select, collection: Folder.where(folder_type: "Source").collect {|c| [c.name, "folder_id:c.id"]}
  # the field (in this case :id) is a placeholder or ransack
  # will crash
  config.add_predicate 'with_integer', # Name your predicate
    # What non-compound ARel predicate will it use? (eq, matches, etc)
    arel_predicate: 'eq'
    # Format incoming values as you see fit. (Default: Don't do formatting)
    #formatter: proc { |v| "#{v}-diddly" },
    
    # Validate a value. An "invalid" value won't be used in a search.
    # Below is default.
    #validator: proc { |v| v.present? },
    
    # Should compounds be created? Will use the compound (any/all) version
    # of the arel_predicate to create a corresponding any/all version of
    # your predicate. (Default: true)
    #compounds: true,
    
    # Force a specific column type for type-casting of supplied values.
    # (Default: use type from DB column)
   # type: :string
end