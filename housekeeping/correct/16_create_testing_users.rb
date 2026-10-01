# encoding: UTF-8

require "securerandom"

#users = [
#  {name: 'Admin', email: 'admin@rism.info', password: 'password', role: 'admin', :workgroup},
#]

role = Role.where(:name => "cataloger").take
wg = Workgroup.where(:id => 8).take #USA
password = "aA1#{SecureRandom.alphanumeric(17)}"

(1..99).each do |n|

  number = str = format('%02d', n)
    
  User.create!(:name => "Training User #{number}",  :username => "Training User #{number}", :email => "training#{number}@rism.info", :roles => [role],
               :password => password, :password_confirmation => password, :workgroups => [wg])
end

puts "Training user password: #{password}"
