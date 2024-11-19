ActiveAdmin.register AuthorizationToken do
    menu :parent => "admin_menu", :label => proc {I18n.t(:authorization_tokens)}, :if => proc{ can? :manage, AuthorizationToken }

    permit_params [:active, :name, :token, :comment]
    config.clear_action_items!


    filter :name_cont, :as => :string

    sidebar :actions, :only => :index do
        render :partial => "activeadmin/section_sidebar_index"
      end

end