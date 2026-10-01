# LegacyFile provides read-only access to a YAML dump of a legacy Muscat DB.
#
# Usage:
#
#   legacy = LegacyFile.new("muscat_legacy.yml")
#
#   legacy.tables
#   legacy.table?(:sources)
#   legacy.count(:sources)
#   legacy.columns(:sources)
#
#   legacy.all(:sources)                         # all rows
#   legacy.find(:sources, 123)                   # find by id
#   legacy.get(:sources, 123, :title)            # get one value
#   legacy.find_by(:people, :name, "Mozart")     # first match
#   legacy.where(:sources, library_id: 45)       # all matches
#   legacy.pluck(:sources, :id)                  # one column
#
# A different lookup key can be used:
#
#   legacy.find(:institutions, "D-B", :siglum)
#
# Relationships are followed explicitly:
#
#   legacy.where(:sources_people, source_id: 123).each do |link|
#     person = legacy.find(:people, link["person_id"])
#   end
#
# The dump contains plain hashes/arrays, not ActiveRecord objects.
# Lookup indexes are built in memory when needed.
#
# The YAML is loaded with YAML.unsafe_load_file because database values may
# contain Time/Date objects. Only use LegacyFile with trusted dump files.
#
# LegacyFile never modifies the dump or connects to the legacy database.

require "yaml"

class LegacyFile
  attr_reader :path

  def initialize(path)
    @path = path

    @data = YAML.safe_load_file(
      path,
      permitted_classes: [Time, Date, DateTime],
      aliases: true
    )

    @tables = @data.fetch("tables")

    @indexes = {}
  end

  # --------------------------------------------------
  # Basic table access
  # --------------------------------------------------

  def tables
    @tables.keys
  end

  def table(name)
    @tables.fetch(name.to_s)
  end

  alias_method :all, :table

  def count(name)
    table(name).size
  end

  # --------------------------------------------------
  # Find by primary key
  #
  # legacy.find(:sources, 123)
  # --------------------------------------------------

  def find(table_name, id, key = :id)
    index(table_name, key)[normalize(id)]
  end

  # --------------------------------------------------
  # Get one value
  #
  # legacy.get(:sources, 123, :name)
  # --------------------------------------------------

  def get(table_name, id, column, key = :id)
    row = find(table_name, id, key)

    return nil unless row

    row[column.to_s]
  end

  # --------------------------------------------------
  # Find first matching row
  #
  # legacy.find_by(:sources, :lib_siglum, "D-B")
  # --------------------------------------------------

  def find_by(table_name, column, value)
    table(table_name).find do |row|
      row[column.to_s] == value
    end
  end

  # --------------------------------------------------
  # Find all matching rows
  #
  # legacy.where(:sources, :library_id, 123)
  #
  # or:
  #
  # legacy.where(:sources, library_id: 123, deleted: 0)
  # --------------------------------------------------

  def where(table_name, column = nil, value = nil, **conditions)
    if column
      conditions[column] = value
    end

    table(table_name).select do |row|
      conditions.all? do |key, expected|
        row[key.to_s] == expected
      end
    end
  end

  # --------------------------------------------------
  # Extract a column
  #
  # legacy.pluck(:sources, :id)
  # --------------------------------------------------

  def pluck(table_name, column)
    table(table_name).map { |row| row[column.to_s] }
  end

  # --------------------------------------------------
  # Does table exist?
  # --------------------------------------------------

  def table?(name)
    @tables.key?(name.to_s)
  end

  # --------------------------------------------------
  # Column names
  # --------------------------------------------------

  def columns(table_name)
    row = table(table_name).first

    row ? row.keys : []
  end

  # --------------------------------------------------
  # Metadata
  # --------------------------------------------------

  def metadata
    @data["metadata"] || {}
  end

  private

  def index(table_name, key)
    cache_key = [table_name.to_s, key.to_s]

    @indexes[cache_key] ||= begin
      table(table_name).each_with_object({}) do |row, result|
        value = row[key.to_s]

        result[normalize(value)] = row unless value.nil?
      end
    end
  end

  def normalize(value)
    value.to_s
  end
end