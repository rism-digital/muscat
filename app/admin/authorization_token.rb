ActiveAdmin.register AuthorizationToken do
    menu :parent => "admin_menu", :label => proc {I18n.t(:authorization_tokens)}, :if => proc{ can? :manage, AuthorizationToken }

    permit_params [:active, :name, :token, :comment]
    config.clear_action_items!

    sidebar :actions, :only => :index do
        render :partial => "activeadmin/filter_workaround"
        render :partial => "activeadmin/section_sidebar_index"
      end

end