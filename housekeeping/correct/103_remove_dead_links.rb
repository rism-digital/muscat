# Find all models whose table name includes '_to_'
# These by convention are in the relations/ directory,
# and the ruby name is like WorkNodePublicationRelation

join_models = ApplicationRecord.descendants.select do |klass|
  # Exclude abstract classes (like ApplicationRecord itself)
  !klass.abstract_class? && klass.table_name.include?('_to_')
end

join_models.each do |join_model|
  # Each one of these has exactly 2 belongs_to, since it is a
  # relation table
  belongs_associations = join_model.reflect_on_all_associations(:belongs_to)
  next unless belongs_associations.size == 2

  # Construct a LEFT JOIN for each belongs_to and check if either is NULL
  left_joins_args = belongs_associations.map(&:name)

  # "table1.id IS NULL OR table2.id IS NULL"
  null_checks = belongs_associations
    .map { |assoc| "#{assoc.klass.table_name}.id IS NULL" }
    .join(" OR ")

  dead_links = join_model
    .left_joins(*left_joins_args)
    .where(null_checks)

  # 5. Print or delete them
  count = dead_links.count
  if count > 0
    puts "⚠️  #{join_model.name} has #{count} dead link(s)"
    # If you want to remove them automatically:
    dead_links.delete_all
  end
end