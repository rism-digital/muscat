ActiveAdmin.register_page "Dashboard" do
	
	controller do
	  def index
			store_or_restore(:dashboard_source_owner, :user)
			store_or_restore(:dashboard_source_type, :created)
			store_or_restore(:dashboard_person_owner, :user)
			store_or_restore(:dashboard_person_type, :created)
			store_or_restore(:dashboard_catalogue_owner, :user)
			store_or_restore(:dashboard_catalogue_type, :created)
			store_or_restore(:dashboard_institution_owner, :user)
			store_or_restore(:dashboard_institution_type, :created)
			store_or_restore(:dashboard_quantity, 10)
	  end
		
	
		# Store or restore session parameter
		def store_or_restore(value, default)
			# we have a parameter, store it
			if (params[value] != nil) && (params[value] != "")
				session[value] = params[value] 
			# we have something store, restore it
			elsif (session[value]) != nil && (session[value] != "")
				params[value] = session[value]
			# default
			else
				params[value] = default
			end
		end
	end
  
	#menu priority: 3, label: proc{ I18n.t("active_admin.dashboard") }
  menu false
  
  limit = 10;

  content title: proc{ I18n.t("active_admin.dashboard") } do
    
    #user = current_user.has_any_role?(:editor, :admin) ? -1 : current_user.id
		user = (params[:dashboard_source_owner] == :user) ? current_user.id : -1
		sources = Source.find_recent_modified(params[:dashboard_quantity], params[:dashboad_source_type], user)
    if sources.size > 0
      columns do
        column do
          panel "#{Source.model_name.human(count: 2)}  -  #{I18n.t(:recent_changes)}" do
            table_for sources.map do
              column(I18n.t :filter_id) {|source| link_to(source.id, admin_source_path(source)) }
              column(I18n.t :filter_wf_stage) {|source| status_tag(source.wf_stage) } 
              column(I18n.t :filter_composer) {|source| source.composer }
              column(I18n.t :filter_title) {|source| source.title } 
            end
          end
        end
      end
    end
    
		user = (params[:dashboard_person_owner] == :user) ? current_user.id : -1	
		people = Person.find_recent_modified(params[:dashboard_quantity], params[:dashboad_source_type], user)
    if people.size > 0
      columns do
        column do
          panel "#{Person.model_name.human(count: 2)}  -  #{I18n.t(:recent_changes)}" do
            table_for people.map do
              column(I18n.t :filter_id) {|person| link_to(person.id, admin_person_path(person)) }
              column(I18n.t :filter_wf_stage) {|person| status_tag(person.wf_stage) } 
              column (I18n.t :filter_full_name) {|person| person.full_name }
              #column (I18n.t :filter_sources) {|person| person.src_count }
            end
          end
        end
      end
    end

		user = (params[:dashboard_catalogue_owner] == :user) ? current_user.id : -1
		catalogues = Catalogue.find_recent_modified(params[:dashboard_quantity], params[:dashboad_source_type], user)
    if catalogues.size > 0
      columns do
        column do
          panel "#{Catalogue.model_name.human(count: 2)}  -  #{I18n.t(:recent_changes)}" do
            table_for catalogues.map do
              column(I18n.t :filter_id) {|catalogue| link_to(catalogue.id, admin_catalogue_path(catalogue)) }
              column(I18n.t :filter_wf_stage) {|catalogue| status_tag(catalogue.wf_stage) } 
              column (I18n.t :filter_name) {|catalogue| catalogue.name }
              column (I18n.t :filter_author) {|catalogue| catalogue.author }
              #column (I18n.t :filter_sources) {|person| person.src_count }
            end
          end
        end
      end
    end

  end # content
	
  sidebar I18n.t "dashboard.selection", :class => "sidebar_tabs", :only => [:index] do
    # no idea why the I18n.locale is not set by set_locale in the ApplicationController
    I18n.locale = session[:locale]
    render("dashboard_sidebar") # Calls a partial
  end
	
end
