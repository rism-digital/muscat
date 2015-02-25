ActiveAdmin.register_page "Administration" do
  menu :parent => "admin_menu", :if => proc{ can? :manage, :all }

  content do
    panel "Current active users" do 
      table_for User.all.select{|user|user.online?} do
        column :id
        column :name
        column :roles do |user|
          user.roles.pluck(:name).join(", ").capitalize
        end
        column :updated_at
      end
    end

    panel "Logfile Errors" do
      cmd='tail -n 10000 '+Rails.root.join('log', 'development.log').to_s+' | egrep -B 1 "Error"'
      s=`#{cmd}`
      text_node s.html_safe
    end
   
   
    render 'index'
  end
end
