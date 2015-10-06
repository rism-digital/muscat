ActiveAdmin.register Source do
  
  collection_action :autocomplete_source_id, :method => :get
  collection_action :autocomplete_source_740_autocomplete_sms, :method => :get

  # Remove mass-delete action
  batch_action :destroy, false
  
  menu :priority => 10, :label => proc {I18n.t(:menu_sources)}

  breadcrumb do
    active_admin_muscat_breadcrumb
  end
    
  action_item :view, only: :show, if: proc{ is_selection_mode? } do
    active_admin_muscat_select_link( source )
  end
  
  action_item :view, only: [:index, :show], if: proc{ is_selection_mode? } do
    active_admin_muscat_cancel_link
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    before_filter :only => [:index] do
        if params['commit'].blank?
                 #params['q'] = {:std_title_contains => "[Holding]"} 
        end
    end
    autocomplete :source, :id, {:display_value => :autocomplete_label , :extra_data => [:std_title, :composer], :solr => false}
    autocomplete :source, "740_autocomplete_sms", :solr => true
    
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
      @editor_profile = EditorConfiguration.get_show_layout @item
      @prev_item, @next_item, @prev_page, @next_page = Source.near_items_as_ransack(params, @item)
      
      respond_to do |format|
        format.html
        format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions) }
      end
    end

    def edit
      @item = Source.find(params[:id])
      @show_history = true if params[:show_history]
      @editor_profile = EditorConfiguration.get_applicable_layout @item
      @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
    end

    def index
      @results = Source.search_as_ransack(params)
      index! do |format|
       @sources = @results
        format.html
      end
    end

    def new
      @source = Source.new
      @based_on = String.new
      
      if (!params[:existing_title] || params[:existing_title].empty?) && (!params[:new_type] || params[:new_type].empty?)
        redirect_to action: :select_new_template
        return
      end

      if params[:existing_title] and !params[:existing_title].empty?
        @based_on = "exsiting title"
        base_item = Source.find(params[:existing_title])
        new_marc = MarcSource.new(base_item.marc.marc_source)
        new_marc.load_source false # this will need to be fixed
        new_marc.first_occurance("001").content = "__TEMP__"
        @source.marc = new_marc
      elsif File.exists?("#{Rails.root}/config/marc/#{RISM::BASE}/source/" + params[:new_type] + '.marc')
        @based_on = params[:new_type]
        new_marc = MarcSource.new(File.read("#{Rails.root}/config/marc/#{RISM::BASE}/source/" +params[:new_type] + '.marc'))
        new_marc.load_source false # this will need to be fixed
        @source.marc = new_marc
      end
      @editor_profile = EditorConfiguration.get_applicable_layout @source
      @page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
      #To transmit correctly @item we need to have @source initialized
      @item = @source
    end

  end
  
  #batch_action :unpublish do |selection|
  #end
  
  
  # Include the MARC extensions
  include MarcControllerActions
  
  # Include the folder actions
  include FolderControllerActions
  
  collection_action :select_new_template, :method => :get
  
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
  filter :lib_siglum_contains, :label => proc{I18n.t(:library_sigla_contains)}, :as => :string
  # This filter is the "any field" one
  filter :title_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "Source").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  # and for the wf_owner
  filter :wf_owner_with_integer, :label => proc {I18n.t(:filter_owner)}, as: :select, 
         collection: proc {
           if current_user.has_any_role?(:editor, :admin)
             User.all.collect {|c| [c.name, "wf_owner:#{c.id}"]}
           else
             [[current_user.name, "wf_owner:#{current_user.id}"]]
           end
         }
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_wf_stage) {|source| status_tag(source.wf_stage)} 
    column (I18n.t :filter_composer), :composer
    column (I18n.t :filter_std_title), :std_title
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_lib_siglum), sortable: :lib_siglum do |source|
      if source.sources.count>0
         source.sources.map(&:lib_siglum).uniq.reject{|s| s.empty?}.sort.join(", ").html_safe
      else
        source.lib_siglum
      end
    end
    column (I18n.t :filter_shelf_mark), :shelf_mark
    
    active_admin_muscat_actions( self )
  end
  
  ##########
  ## Show ##
  ##########
  
  show :title => proc{ active_admin_source_show_title( @item.composer, @item.std_title, @item.id) } do
    # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
    active_admin_navigation_bar( self )
    @item = @arbre_context.assigns[:item]
    render :partial => "marc/show"
    active_admin_navigation_bar( self )
    active_admin_user_wf( self, @item )
    active_admin_comments if !is_selection_mode?
  end
  
  ##########
  ## Edit ##
  ##########
  
  sidebar :sections, :class => "sidebar_tabs", :only => [:edit, :new] do
    render("editor/section_sidebar") # Calls a partial
  end
  
  form :partial => "editor/edit_wide"
  
end
