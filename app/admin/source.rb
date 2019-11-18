ActiveAdmin.register Source do
  
  collection_action :autocomplete_source_id, :method => :get
  collection_action :autocomplete_source_740_autocomplete_sms, :method => :get
  collection_action :autocomplete_source_594b_sms, :method => :get

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]
  
  menu :priority => 10, :label => proc {I18n.t(:menu_sources)}

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    after_destroy :check_model_errors

    before_action :only => [:index] do
        if params['commit'].blank?
                 #params['q'] = {:std_title_contains => "[Holding]"} 
        end
    end
    autocomplete :source, :id, {:display_value => :autocomplete_label , :extra_data => [:std_title, :composer], :exact_match => true, :solr => false}
    autocomplete :source, "740_autocomplete_sms", :solr => true
    autocomplete :source, "594b_sms", :solr => true
    

    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
    
    def action_methods
      return super - ['new', 'edit', 'destroy'] if is_selection_mode?
      super
    end
    
    def permitted_params
      params.permit!
    end
    
    def show
      begin
        @item = Source.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Source #{params[:id]})" }
        return
      end

      # Try to load the MARC object.
      begin
        @item.marc.load_source true
      rescue ActiveRecord::RecordNotFound
        # If resolving the remote objects fails, it means
        # Something went wrong saving the source, like a DB falure
        # continue to show the page so the user does not panic, and
        # show an error message. Also send a mail to the administrators
        flash[:error] = I18n.t(:unloadable_record)
        AdminNotifications.notify("Source #{@item.id} seems unloadable, please check", @item).deliver_now
      end
      
      @editor_profile = EditorConfiguration.get_show_layout @item
      @prev_item, @next_item, @prev_page, @next_page = Source.near_items_as_ransack(params, @item)
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end

    def edit
      flash.now[:error] = params[:validation_error] if params[:validation_error]
      @item = Source.find(params[:id])
      @holdings = @item.holdings
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      record_type = @item.get_record_type
      record_type = record_type ? " - #{I18n.t('record_types.' + record_type.to_s)}" : ""
      @page_title = "#{I18n.t(:edit)}#{record_type} [#{@item.id}]"
      
      template = EditorConfiguration.get_source_default_file(@item.get_record_type) + ".marc"
      
      
      # Try to load the MARC object.
      # This is the same trap as in show but here we
      # PREVENT opening the editor. Redirect to the show page
      # and inform the admins.
      begin
        @item.marc.load_source true
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_source_path @item
        return
      end
      
      @item.marc.superimpose_template(template) if template
    end

    def index
      @results, @hits = Source.search_as_ransack(params)

      # Get the terms for 593a_filter, the "source type"
      @source_types = Source.get_tems("593a_filter_sm")

      index! do |format|
       @sources = @results
        format.html
      end
    end

    def new
      @source = Source.new
      @template_name = ""
      
      if (!params[:existing_title] || params[:existing_title].empty?) && (!params[:new_record_type] || params[:new_record_type].empty?)
        redirect_to action: :select_new_template 
        return
      end

      if params[:existing_title] and !params[:existing_title].empty?
        # Check that the record does exist...
        begin
          base_item = Source.find(params[:existing_title])
        rescue ActiveRecord::RecordNotFound
          redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Source #{params[:id]})" }
          return
        end
        
        new_marc = MarcSource.new(base_item.marc.marc_source, base_item.record_type)
        # Reset the basic fields to default values
        new_marc.reset_to_new
        # copy the record type
        @source.marc = new_marc
        @source.record_type = base_item.record_type
        @template_name = @source.get_record_type.to_s
      else 
        
        default_file_name = EditorConfiguration.get_source_default_file(params[:new_record_type])
        default_file = "#{Rails.root}/config/marc/#{RISM::MARC}/source/" + default_file_name + '.marc'
        
        if File.exists?(default_file)
          new_marc = MarcSource.new(File.read(default_file), MarcSource::RECORD_TYPES[params[:new_record_type].to_sym])
          new_marc.load_source false # this will need to be fixed
          @source.marc = new_marc
          @template_name = params[:new_record_type]
          @source.record_type = MarcSource::RECORD_TYPES[params[:new_record_type].to_sym]
        end
      end

      @editor_profile = EditorConfiguration.get_default_layout(@source)
      @editor_validation = EditorValidation.get_default_validation(@source)
      @page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{I18n.t('record_types.' + @template_name)}"
      #To transmit correctly @item we need to have @source initialized
      @item = @source
    end

  end
    
  # Include the MARC extensions
  include MarcControllerActions
  
  member_action :duplicate, method: :get do
    redirect_to action: :new, :existing_title => params[:id]
    return
  end
  
  collection_action :select_new_template, :method => :get do 
    @page_title = "#{I18n.t(:select_template)}"
  end
  
  #scope :all, :default => true 
  #scope :published do |sources|
  #  sources.where(:wf_stage => 'published')
  #end
  
  ###########
  ## Index ##
  ###########  

  # filers
  filter :title_contains, :label => proc{I18n.t(:title_contains)}, :as => :string
  filter :std_title_contains, :label => proc{I18n.t(:std_title_contains)}, :as => :string
  filter :composer_contains, :label => proc{I18n.t(:composer_contains)}, :as => :string
  
  filter :"852a_facet_contains", :label => proc{I18n.t(:library_sigla_contains)}, :as => :string, if: proc { !is_selection_mode? }
  # see See lib/active_admin_record_type_filter.rb
  # The same as above, but when the lib siglum is forced and cannot be changes
  filter :lib_siglum_with_integer,
  if: proc { is_selection_mode? == true && params.include?(:q) && params[:q].include?(:lib_siglum_with_integer)},
  :as => :lib_siglum
  
  # This filter is the "any field" one
  filter :title_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  filter :updated_at, :label => proc{I18n.t(:updated_at)}, as: :date_range
  filter :created_at, :label => proc{I18n.t(:created_at)}, as: :date_range
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.for_type("Source").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  # and for the wf_owner
  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, as: :select, 
         collection: proc {
           if current_user.has_any_role?(:editor, :admin)
             User.sort_all_by_last_name.map{|u| [u.name, "wf_owner:#{u.id}"]}
           else
             [[current_user.name, "wf_owner:#{current_user.id}"]]
           end
         }
  
  filter :"593a_filter_with_integer", :label => proc{I18n.t(:filter_source_type)}, as: :select, 
  collection: proc{@source_types.sort.collect {|k| [k.camelize, "593a_filter:#{k}"]}}
  
  filter :record_type_select_with_integer, as: :select, 
  collection: proc{MarcSource::RECORD_TYPE_ORDER.collect {|k| [I18n.t("record_types." + k.to_s), "record_type:#{MarcSource::RECORD_TYPES[k]}"]}},
	if: proc { !is_selection_mode? }, :label => proc {I18n.t(:filter_record_type)}

  # See lib/active_admin_record_type_filter.rb
  filter :record_type_with_integer,
  if: proc { is_selection_mode? == true && params.include?(:q) && params[:q].include?(:record_type_with_integer)},
  :as => :record_type

  filter :wf_stage_with_integer, :label => proc {I18n.t(:filter_wf_stage)}, as: :select, 
  collection: proc{[:inprogress, :published, :deleted].collect {|v| [I18n.t("wf_stage." + v.to_s), "wf_stage:#{v}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|source| status_tag(source.wf_stage,
      label: I18n.t('status_codes.' + (source.wf_stage != nil ? source.wf_stage : ""), locale: :en))} 
    column (I18n.t :filter_record_type_short) {|source| status_tag(source.get_record_type.to_s, 
      label: I18n.t('record_types_codes.' + (source.record_type != nil ? source.record_type.to_s : ""), locale: :en))} 
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_composer), :composer
    column (I18n.t :filter_std_title), :std_title_shelforder, sortable: :std_title_shelforder do |element|
      element.std_title
    end
    column (I18n.t :filter_lib_siglum), sortable: :lib_siglum do |source|
      if source.child_sources.count > 0
         source.child_sources.map(&:lib_siglum).uniq.reject{|s| s.empty?}.sort.join(", ").html_safe
      else
        source.lib_siglum
      end
    end
    column (I18n.t :filter_shelf_mark), :shelf_mark_shelforder, sortable: :shelf_mark_shelforder do |element|
      element.shelf_mark
    end
    if current_user.has_any_role?(:admin, :editor)
      column "Level" do |element|
        element.tag_rate
      end
    end

    
    active_admin_muscat_actions( self )
  end
  
  sidebar :actions, :only => :index do
    render :partial => "activeadmin/filter_workaround"
    render :partial => "activeadmin/section_sidebar_index"
  end
  
  # Include the folder actions
  include FolderControllerActions
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_source_show_title( @item.composer, @item.std_title, @item.id, @item.get_record_type) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    render :partial => "marc/show"
    active_admin_embedded_source_list( self, @item, !is_selection_mode? )
    active_admin_digital_object( self, @item ) if !is_selection_mode?
    active_admin_user_wf( self, @item )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => @arbre_context.assigns[:item] }
  end

  sidebar I18n.t(:holding_records), :only => :show , if: proc{ !resource.holdings.empty? } do
    render :partial => "holdings/holdings_sidebar_show"#, :locals => { :item => @arbre_context.assigns[:item] }
  end
  
  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :class => "sidebar_tabs", :only => [:edit, :new, :update] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  sidebar :help, :only => [:select_new_template] do
    render :partial => "template_help"
  end

  form :partial => "editor/edit_wide"
  
end
