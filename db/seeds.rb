# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
Role.create :name => "admin"
Role.create :name => "editor"
Role.create :name => "cataloger"
Role.create :name => "guest"
Role.create :name => "junior_editor"
User.create!(:name => "Admin", :email => 'admin@example.com', :roles => [Role.first], :password => 'password', :password_confirmation => 'password')
