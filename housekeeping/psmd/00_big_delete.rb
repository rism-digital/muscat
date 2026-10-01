DRY_RUN = false

connection = ActiveRecord::Base.connection

start_time = Time.zone.now.beginning_of_day.utc
end_time   = Time.zone.now.end_of_day.utc

puts "Deleting records created between:"
puts "  #{start_time}"
puts "  #{end_time}"
puts
puts DRY_RUN ? "DRY RUN - nothing will be deleted" : "LIVE DELETE"
puts

ignored_tables = %w[
  schema_migrations
  ar_internal_metadata
]

tables = connection.tables.reject { |t| ignored_tables.include?(t) }

connection.transaction do
  connection.disable_referential_integrity do
    tables.each do |table|
      columns = connection.columns(table).map(&:name)

      next unless columns.include?("created_at")

      quoted_table = connection.quote_table_name(table)

      start_sql = connection.quote(start_time)
      end_sql   = connection.quote(end_time)

      condition = <<~SQL.squish
        created_at >= #{start_sql}
        AND created_at <= #{end_sql}
      SQL

      count = connection.select_value(
        "SELECT COUNT(*) FROM #{quoted_table} WHERE #{condition}"
      ).to_i

      next if count.zero?

      puts "#{table}: #{count}"

      unless DRY_RUN
        connection.execute(
          "DELETE FROM #{quoted_table} WHERE #{condition}"
        )
      end
    end
  end

  raise ActiveRecord::Rollback if DRY_RUN
end

puts
puts DRY_RUN ? "Dry run complete." : "Delete complete."