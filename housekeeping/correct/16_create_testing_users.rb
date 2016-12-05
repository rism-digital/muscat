# encoding: UTF-8

#users = [
#  {name: 'Admin', email: 'admin@rism.info', password: 'password', role: 'admin', :workgroup},
#]

role = Role.where(:name => "cataloger").take
wg = Workgroup.where(:id => 8).take #USA

(1..50).each do |n|

  number = str = format('%02d', n)
    
  User.create!(:name => "training#{number}",  :email => "training#{number}@rism.info", :roles => [role],
               :password => "password",  :password_confirmation => "password", :workgroups => [wg])

end
