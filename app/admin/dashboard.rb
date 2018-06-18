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
    user_id = (params[:dashboard_source_owner].to_s == "user") ? current_user.id : -1
    sources = dashboard_find_recent(Source, params[:dashboard_quantity], params[:dashboard_source_type], user_id, 15)
    columns do
      column do
        panel "#{Source.model_name.human(count: 2)}" do
          table_for sources.map do
            column (I18n.t :filter_wf_stage) {|source| status_tag(source.wf_stage,
              label: I18n.t('status_codes.' + (source.wf_stage != nil ? source.wf_stage : ""), locale: :en))} 
            column (I18n.t :filter_record_type) {|source| status_tag(source.get_record_type.to_s, 
              label: I18n.t('record_types_codes.' + (source.record_type != nil ? source.record_type.to_s : ""), locale: :en))} 
            column(I18n.t :filter_id) {|source| link_to(source.id, admin_source_path(source)) }
            column(I18n.t :filter_composer) {|source| source.composer }
            column(I18n.t :filter_std_title) {|source| source.std_title } 
            column (I18n.t :filter_lib_siglum), :lib_siglum do |source|
              if source.child_sources.count > 0
                 source.child_sources.map(&:lib_siglum).uniq.reject{|s| s.empty?}.sort.join(", ").html_safe
              else
                source.lib_siglum
              end
            end
            column(I18n.t :filter_shelf_mark) {|source| source.shelf_mark } 
          end
        end
      end
    end
    
    user_id = (params[:dashboard_person_owner].to_s == "user") ? current_user.id : -1  
    people = dashboard_find_recent(Person, params[:dashboard_quantity], params[:dashboard_person_type], user_id)
    columns do
      column do
        panel "#{Person.model_name.human(count: 2)}" do
          table_for people.map do
            column (I18n.t :filter_wf_stage) {|person| status_tag(person.wf_stage,
              label: I18n.t('status_codes.' + (person.wf_stage != nil ? person.wf_stage : ""), locale: :en))} 
            column (I18n.t :filter_id) {|person| link_to(person.id, admin_person_path(person)) }
            column (I18n.t :filter_full_name), :full_name
            column (I18n.t :filter_life_dates), :life_dates
            column (I18n.t :filter_owner) {|person| User.find(person.wf_owner).name rescue 0} if current_user.has_any_role?(:editor, :admin)
          end
        end
      end
    end

    user_id = (params[:dashboard_catalogue_owner].to_s == "user") ? current_user.id : -1
    catalogues = dashboard_find_recent(Catalogue, params[:dashboard_quantity], params[:dashboard_catalogue_type], user_id)
    columns do
      column do
        panel "#{Catalogue.model_name.human(count: 2)}" do
          table_for catalogues.map do
            column (I18n.t :filter_wf_stage) {|catalogue| status_tag(catalogue.wf_stage,
              label: I18n.t('status_codes.' + (catalogue.wf_stage != nil ? catalogue.wf_stage : ""), locale: :en))}  
            column (I18n.t :filter_id) {|catalogue| link_to(catalogue.id, admin_catalogue_path(catalogue)) }
            column (I18n.t :filter_name), :name do |catalogue| 
              catalogue.name.truncate(30) if catalogue.name
            end
            column (I18n.t :filter_description), :description do |catalogue| 
              catalogue.description.truncate(60) if catalogue.description
            end
            column (I18n.t :filter_author), :author
          end
        end
      end
    end

    user_id = (params[:dashboard_institution_owner].to_s == "user") ? current_user.id : -1
    institutions = dashboard_find_recent(Institution, params[:dashboard_quantity], params[:dashboard_institution_type], user_id)
    columns do
      column do
        panel "#{Institution.model_name.human(count: 2)}" do
          table_for institutions.map do
            column (I18n.t :filter_wf_stage) {|institution| status_tag(institution.wf_stage,
              label: I18n.t('status_codes.' + (institution.wf_stage != nil ? institution.wf_stage : ""), locale: :en))}  
            column (I18n.t :filter_id) {|institution| link_to(institution.id, admin_institution_path(institution)) } 
            column (I18n.t :filter_siglum), :siglum
            column (I18n.t :filter_location_and_name), :name
            column (I18n.t :filter_place), :place
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
