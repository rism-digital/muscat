# Can be run directly with ruby
# without rails
require 'YAML'

if ARGV.length == 0
    puts "please provide a new database name"
    exit(1)
end

rails_env = "production"
rails_env = ENV["RAILS_ENV"] if ENV.keys.include?("RAILS_ENV")

databases = YAML::load(File.read("config/database.yml"))

databases[rails_env]["database"] = ARGV[0]

File.open("config/database.yml", "w") { |file| file.write(databases.to_yaml) }