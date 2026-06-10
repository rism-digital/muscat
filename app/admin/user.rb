ActiveAdmin.register User do
  menu :parent => "admin_menu", :label => proc {I18n.t(:menu_users)}, :if => proc{ (can? :read, User) || current_user.has_role?(:editor)}
  
  permit_params :preference_wf_stage, :email, :password, :password_confirmation, 
                :username, :name, :notifications, :notification_type, :notification_email, 
                :disabled, workgroup_ids: [], role_ids: []

  # Remove all action items
  config.clear_action_items!
	config.per_page = [10, 30, 50, 100, 1000]

  order_by(:role_sort_name) do |order_clause|
    "role_sort_name #{order_clause.order}"
  end

	controller do

    def apply_sorting(chain)
      if params[:order].to_s.match?(/\Aroles(?:\.|_)name_/)
        params[:order] = params[:order].to_s.sub(/\Aroles(?:\.|_)name_/, "role_sort_name_")
      end

      super
    end

    def scoped_collection
      super
        .left_joins(:roles)
        .select(<<~SQL.squish)
          users.*,
          COALESCE(
            MIN(
              CASE roles.name
                WHEN 'admin' THEN 1
                WHEN 'editor' THEN 2
                WHEN 'cataloger' THEN 4
                WHEN 'guest' THEN 5
                ELSE 6
              END
            ),
            0
          ) AS role_sort_name
        SQL
        .group("users.id")
    end

	  def update
	    if params[:user][:password].blank? && params[:user][:password_confirmation].blank?
	      params[:user].delete("password")
	      params[:user].delete("password_confirmation")
	    end
	    super
	  end

	end

  # this is used by tribute_load.js
  collection_action :list, method: :post do
    params.permit!
    if params.include?(:q)
      users = User.where("name REGEXP ?", "\\b#{params[:q]}").collect {|u| {name: u.name, id: u.name.gsub(" ", "_")}}
    else
      users = []
    end

    users.reject! {|u| u[:name] == "Admin"}
    
    respond_to do |format|
        format.json { render json: users  }
    end
  end

  # And this is used by thle flexdatalist for the user selection
  collection_action :list_for_filter, method: :get do
    if current_user.has_any_role?(:editor, :admin)
      users = User.all.map {|u| {name: u.name, id: "wf_owner:#{u.id}", shortid: u.id} }
    else
      users = [{name: current_user.name, id: "wf_owner:#{current_user.id}", shortid: current_user.id}]
    end
    respond_to do |format|
        format.json { render json: users  }
    end
  end

  # Button to add a default wg to the user
  action_item :create_default_workgroup, only: [:show, :edit] do
    if authorized?(:admin, User) && resource.default_workgroup.blank?
      link_to "Create personal default Workgroup",
              create_default_workgroup_admin_user_path(resource),
              method: :post
    end
  end

  # And the implementation of the above
  member_action :create_default_workgroup, method: :post do
    authorize! :admin, User

    user = User.find(params[:id])

    if user.default_workgroup.present?
      redirect_to resource_path(user), alert: "User already has a personal default workgroup"
      next
    end

    workgroup = Workgroup.create!(
      name: "Default for #{user.username.presence || user.email}",
      personal_default: true,
      owner_user: user
    )

    user.workgroups << workgroup

    redirect_to resource_path(user), notice: "Personal default workgroup created"
  end

  ###########
  ## Index ##
  ###########

  filter :username
  filter :name
  filter :email
  filter :roles_id_in,
       as: :select,
       label: I18n.t(:roles),
       collection: -> { Role.order(:name).pluck(:name, :id) }
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  index download_links: false,
    row_class: ->(user) do
      return 'disabled-user' if user.disabled?
      return 'admin-user' if user.has_role? :admin
      return 'editor-user' if user.has_role? :editor
      return 'guest-user' if user.has_role? :guest
    end do

    selectable_column
    id_column
    
    column :status, sortable: :disabled do |user|
      status_tag(
        user.disabled? ? 'DIS' : 'ENA',
        class: user.disabled? ? 'deleted' : 'ok'
      )
    end

    column :active do |user|
      user.active?
    end

    column :username
    column :name
    column :email
    column I18n.t(:workgroups) do |user|
         user.get_workgroups.join(", ")
    end
    column I18n.t(:roles), sortable: "role_sort_name" do |user|
      user.get_roles.join(", ")
    end
    column :sign_in_count
    column :current_sign_in_at
    #column :created_at
    #column (I18n.t :filter_sources) do |user|
    #  user.sources_size_per_month(Time.now - 1.month, Time.now)
    #end
    #
    actions
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/section_sidebar_index"
  end
 
  # Include the folder actions
  include FolderControllerActions
  
  ##########
  ## Show ##
  ##########

  show do
    attributes_table do
      row :username
      row :name
      row :email
      row I18n.t(:workgroups) do |user|
        safe_join(
          user.workgroups.map do |wg|
            label = wg.personal_default? ? "#{wg.name} **" : wg.name
            link_to(label, admin_workgroup_path(wg))
          end,
          ", ".html_safe
        )
      end
      row I18n.t(:roles) do |user|
           user.get_roles.join(", ")
      end
      row I18n.t('notifications.notifications') do |r|
        r.notifications ? r.notifications.split(/\n+|\r+/).reject(&:empty?).join("<br>").html_safe : ""
      end
      row I18n.t('notifications.cadence') do |r|
        if !r.notification_type
          I18n.t('notifications.none')
        else
          I18n.t('notifications.' + r.notification_type) + " (#{r.notification_type})"
        end
      end
      if can? :manage, User
        row :notification_email
        row :disabled
      end
      row :sign_in_count
      row :current_sign_in_at
      row :last_sign_in_at
      row :current_sign_in_ip
      row :last_sign_in_ip
      row :created_at
      row :updated_at
    end
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => user }
  end
  
  ##########
  ## Edit ##
  ##########

  # We use a partial here so the formatting for the notifications_help is preserved
  # The form is built in the same manner using formtastic
  form partial: 'user_edit_form'

=begin
  form do |f|
    f.inputs I18n.t(:user_details) do
      if can? :update, User
        f.input :name
        f.input :email
      #elsif can? :update, User
      #  f.input :name, :input_html => {:disabled => true}
      #  f.input :email, :input_html => {:disabled => true}
      end
      
      if can? :update, User
        f.input :password
        f.input :password_confirmation
        ## size does not work unless there is a dummy class. Hooray!
        f.input :notifications, :input_html => { :class => 'placeholder', :rows => 2, :style => 'width:50%'}
        f.input :notification_type, as: :select, multiple: false, collection: [:every, :daily, :weekly]
      end
      if can? :manage, User
        f.input :workgroups, as: :select, multiple: true, collection: Workgroup.all.sort_by {|w| w.name} 
        f.input :roles, as: :select, multiple: false, collection: Role.all
        f.input :preference_wf_stage, as: :select, multiple: false, collection: [:inprogress, :published, :deleted]
      end
    end
    render partial: 'notifications_help', locals: { f: f }
  end
=end

  sidebar :actions, :only => [:edit, :new, :update, :create] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => user }
  end

end
