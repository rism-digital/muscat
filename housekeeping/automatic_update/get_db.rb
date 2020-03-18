# Can be run directly with ruby
# without rails
require 'YAML'

rails_env = "production"
rails_env = ENV["RAILS_ENV"] if ENV.keys.include?("RAILS_ENV")

databases = YAML::load(File.read("config/database.yml"))

puts databases[rails_env]["database"]