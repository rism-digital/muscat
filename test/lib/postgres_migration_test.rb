# frozen_string_literal: true

require "minitest/autorun"
load File.expand_path("../../script/migrate_mysql_to_postgres", __dir__)

class MuscatPostgresMigrationTest < Minitest::Test
  def setup
    @migration = MuscatPostgresMigration.allocate
  end

  def test_maps_mysql_text_and_integer_types_to_postgresql_types
    assert_equal "text", @migration.send(:postgres_type, column("mediumtext"))
    assert_equal "bigint", @migration.send(:postgres_type, column("int"))
    assert_equal "boolean", @migration.send(:postgres_type, column("tinyint", column_type: "tinyint(1)"))
    assert_equal "smallint", @migration.send(:postgres_type, column("tinyint", column_type: "tinyint(4)"))
  end

  def test_maps_known_structured_columns_to_jsonb
    assert_equal "jsonb", @migration.send(:postgres_type, column("longtext", table: "people", name: "identifiers"))
    assert_equal "text", @migration.send(:postgres_type, column("longtext", table: "versions", name: "object"))
  end

  def test_does_not_turn_a_sql_null_default_into_text
    assert_equal "", @migration.send(:postgres_default, column("varchar", default: "NULL"))
    assert_equal " DEFAULT false", @migration.send(:postgres_default, column("tinyint", column_type: "tinyint(1)", default: "0"))
  end

  def test_copy_text_escapes_postgresql_copy_delimiters
    assert_equal "\\N", @migration.send(:copy_value, nil)
    assert_equal "one\\ttwo\\nthree\\\\four", @migration.send(:copy_value, "one\ttwo\nthree\\four")
  end

  private

  def column(type, table: "example", name: "value", column_type: nil, default: nil)
    {
      "table_name" => table,
      "column_name" => name,
      "data_type" => type,
      "column_type" => column_type || type,
      "column_default" => default
    }
  end
end
