ActiveAdmin.register_page "Dashboard" do
  
  controller do
    def index
      store_or_restore(:dashboard_source_owner, :user)
      store_or_restore(:dashboard_source_type, :created)
      store_or_restore(:dashboard_person_owner, :user)
      store_or_restore(:dashboard_person_type, :created)
      store_or_restore(:dashboard_publication_owner, :user)
      store_or_restore(:dashboard_publication_type, :created)
      store_or_restore(:dashboard_institution_owner, :user)
      store_or_restore(:dashboard_institution_type, :created)
      store_or_restore(:dashboard_holding_owner, :user)
      store_or_restore(:dashboard_holding_type, :created)
      store_or_restore(:dashboard_work_owner, :user)
      store_or_restore(:dashboard_work_type, :created)

      store_or_restore(:dashboard_quantity, 10)

      @file = get_news_file
      if params.include?(:clear_news) && params[:clear_news] == "true"
        cookies.permanent[:news_file] = @file if @file # we should not get here if it is nil
        flash[:alert] = I18n.t('dashboard.message_silenced')
        @file = nil
      end
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

    def get_news_file
      news_files = Dir.glob("#{Rails.root}/app/views/muscat_news/*.en.md")
      names = news_files.collect{|f| File.basename(f, '.en.md') }
      last_file = names.sort.last
      last_file[0] = '' # strip the _, guaranteed fastest method on stackoverflow

      # Not stored in the cookies.permanent, need to visualize
      return last_file if cookies.permanent[:news_file] == nil
      # Stored in the cookies.permanent, not visualize again
      return nil if cookies.permanent[:news_file] == last_file
      # Different file in the cookies.permanent, show it
      last_file
    end

  end
  
  menu priority: 3, label: proc{ I18n.t("active_admin.dashboard") }
  #menu false
  

  limit = 10

  content title: proc{ I18n.t("active_admin.dashboard") } do 

    # Be a bit pedantic here
    if params[:dashboard_quantity] != "10" && params[:dashboard_quantity] != "20" && params[:dashboard_quantity] != "50"
      limit = 10
    else
      limit = params[:dashboard_quantity].to_i
    end

    @file = @arbre_context.assigns[:file]
    if @file
      panel I18n.t('dashboard.news') do
        render 'muscat_news/' + @file
        render 'dashboard_silence_news'
      end
    end

    if current_user.folders.count > 0
      panel "#{Folder.model_name.human(count: 2)}" do
        render 'expiring_folders_help'
        columns do
          column do
            table_for current_user.folders.order(:delete_date).map do
              column (I18n.t :filter_name) do |folder|
                link_to folder.name, admin_folder_path(folder)
              end
              column (I18n.t :updated_at), :updated_at
              column (I18n.t :"folders.expires") do |folder|
                  label_color = folder.delete_date - Time.now <= 2.weeks ? "deleted" : "warning"
                  label_color = "ok" if folder.delete_date - Time.now - 1.day >= 1.months
                  status_tag label_color, label: folder.delete_date.to_date.to_s
              end
              column :reset do |folder|
                link_to("#{I18n.t :"folders.reset_expiration"}", reset_expiration_admin_folder_path(folder))
              end
            end
          end
        end
      end
    end
    
    h3(I18n.t('dashboard.my_records'))
    br()

    #user = current_user.has_any_role?(:editor, :admin) ? -1 : current_user.id
    user_id = (params[:dashboard_source_owner].to_s == "user") ? current_user.id : -1
    sources = dashboard_find_recent(Source, limit, params[:dashboard_source_type], user_id, 15)
    columns do
      column do
        panel "#{Source.model_name.human(count: 2)}" do
          if sources.count > 0
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
          else
            text_node(I18n.t('dashboard.no_items'))
          end
        end

      end
    end
    
    user_id = (params[:dashboard_person_owner].to_s == "user") ? current_user.id : -1  
    people = dashboard_find_recent(Person, limit, params[:dashboard_person_type], user_id, 15)
    columns do
      column do
        panel "#{Person.model_name.human(count: 2)}" do
          if people.count > 0
            table_for people.map do
              column (I18n.t :filter_wf_stage) {|person| status_tag(person.wf_stage,
                label: I18n.t('status_codes.' + (person.wf_stage != nil ? person.wf_stage : ""), locale: :en))} 
              column (I18n.t :filter_id) {|person| link_to(person.id, admin_person_path(person)) }
              column (I18n.t :filter_full_name), :full_name
              column (I18n.t :filter_life_dates), :life_dates
              column (I18n.t :filter_owner) {|person| User.find(person.wf_owner).name rescue 0} if current_user.has_any_role?(:editor, :admin)
            end
          else
            text_node(I18n.t('dashboard.no_items'))
          end
        end
      end
    end

    user_id = (params[:dashboard_publication_owner].to_s == "user") ? current_user.id : -1
    publications = dashboard_find_recent(Publication, limit, params[:dashboard_publication_type], user_id, 15)
    columns do
      column do
        panel "#{Publication.model_name.human(count: 2)}" do
          if publications.count > 0
            table_for publications.map do
              column (I18n.t :filter_wf_stage) {|publication| status_tag(publication.wf_stage,
                label: I18n.t('status_codes.' + (publication.wf_stage != nil ? publication.wf_stage : ""), locale: :en))}  
              column (I18n.t :filter_id) {|publication| link_to(publication.id, admin_publication_path(publication)) }
              column (I18n.t :filter_title_short), :name do |publication| 
                publication.short_name.truncate(30) if publication.short_name
              end
              column (I18n.t :filter_description), :description do |publication| 
                publication.description.truncate(60) if publication.description
              end
              column (I18n.t :filter_author), :author
            end
          else
            text_node(I18n.t('dashboard.no_items'))
          end
        end
      end
    end

    user_id = (params[:dashboard_institution_owner].to_s == "user") ? current_user.id : -1
    institutions = dashboard_find_recent(Institution, limit, params[:dashboard_institution_type], user_id, 15)
    columns do
      column do
        panel "#{Institution.model_name.human(count: 2)}" do
          if institutions.count > 0
            table_for institutions.map do
              column (I18n.t :filter_wf_stage) {|institution| status_tag(institution.wf_stage,
                label: I18n.t('status_codes.' + (institution.wf_stage != nil ? institution.wf_stage : ""), locale: :en))}  
              column (I18n.t :filter_id) {|institution| link_to(institution.id, admin_institution_path(institution)) } 
              column (I18n.t :filter_siglum), :siglum
              column (I18n.t :filter_location_and_name), :name
              column (I18n.t :filter_place), :place
            end
          else
            text_node(I18n.t('dashboard.no_items'))
          end
        end
      end
    end
		
    user_id = (params[:dashboard_holding_owner].to_s == "user") ? current_user.id : -1
    holdings = dashboard_find_recent(Holding, limit, params[:dashboard_holding_type], user_id, 15)
    columns do
      column do
        panel "#{Holding.model_name.human(count: 2)}" do
          if holdings.count > 0
            table_for holdings.map do
              column (I18n.t :filter_id) {|holding| link_to(holding.id, edit_admin_holding_path(holding)) } 
              column (I18n.t :filter_siglum), :lib_siglum
              column (I18n.t :filter_std_title)  {|holding| holding.source ? holding.source.std_title : "No source"}
              column (I18n.t :filter_author)  {|holding| holding.source ? holding.source.composer : "No source"}
            end
          else
            text_node(I18n.t('dashboard.no_items'))
          end
        end
      end
    end

    user_id = (params[:dashboard_work_owner].to_s == "user") ? current_user.id : -1
    works = dashboard_find_recent(Work, limit, params[:dashboard_work_type], user_id, 15)
    columns do
      column do
        panel "#{Work.model_name.human(count: 2)}" do
          if works.count > 0
            table_for works.map do
              column (I18n.t :filter_wf_stage) {|work| status_tag(work.wf_stage,
                label: I18n.t('status_codes.' + (work.wf_stage != nil ? work.wf_stage : ""), locale: :en))}  
              column (I18n.t :filter_id) {|work| link_to(work.id, admin_work_path(work)) } 
              column(I18n.t :filter_composer) {|work| work.person }
              column (I18n.t :filter_title), :title
            end
          else
            text_node(I18n.t('dashboard.no_items'))
          end
        end
      end
    end

    h3(I18n.t('dashboard.my_comments'))
    br()

    panel I18n.t('dashboard.about_comments'), id: "notice-panel" do
      render 'dashboard_comments_help'
    end


    dashboard_make_comment_section(self, dashboard_get_referring_comments(limit, 15), I18n.t("active_admin.comments.referring_comments"))
    dashboard_make_comment_section(self, dashboard_get_model_comments(limit, 15), I18n.t("active_admin.comments.my_item_comments"))
    dashboard_make_comment_section(self, dashboard_get_my_comments(limit, 15), I18n.t("active_admin.comments.my_own_comments"))


  end # content
  
  sidebar I18n.t "dashboard.selection", :class => "sidebar_tabs", :only => [:index] do
    # no idea why the I18n.locale is not set by set_locale in the ApplicationController
    I18n.locale = session[:locale]
    render("dashboard_sidebar") # Calls a partial
  end
  
end
