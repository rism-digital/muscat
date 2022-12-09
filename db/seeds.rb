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

Role.all.each do |role|
  User.create!(:name => role.name.camelize, :email => "#{role.name}@example.com", :roles => [role], :password => 'Password1234', :password_confirmation => 'Password1234')
end
