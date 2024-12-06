require 'mysql2'
require 'yaml'

client = Mysql2::Client.new(
  username: 'rism',
  password: 'password',
  database: 'inventories',
  socket: '/tmp/mysql.sock',
)

tables = client.query("SHOW TABLES").map { |row| row.values.first }

# Hash per contenere i dati di tutte le tabelle
db_data = {}

tables.each do |table|
  results = client.query("SELECT * FROM #{table}")

  table_data = results.map(&:to_h)

  db_data[table] = table_data
end

yaml_data = db_data.to_yaml

File.write('database_export.yml', yaml_data)

puts "Done!"
