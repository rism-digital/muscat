ActiveAdmin.register_page "session" do
  menu false
  
  page_action :deselect, method: :get do
    render :nothing => true
  end
  
end