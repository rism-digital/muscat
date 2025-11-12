include Triggers
  
ActiveAdmin.register StandardTitle do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_titles)}

  # Remove mass-delete action
  batch_action :destroy, false
 
  include MergeControllerActions
  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100, 1000]

  collection_action :autocomplete_standard_title_title, :method => :get
  collection_action :autocomplete_standard_title_title_no_730, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :standard_title, :title, :string_boundary => true, :display_value => :label, :getter_function => :get_autocomplete_title_with_count
    autocomplete :standard_title, :"title_no_730", :record_field => :title, :string_boundary => true, :display_value => :label, 
                  :getter_function => :get_autocomplete_title_with_count, :getter_options => {skip_730: true}


    # Note: the method (title) and other elements
    # should match in the getter_function_autocomplete_label
    def get_autocomplete_title_with_count(token,  options = {})

      sanit = ActiveRecord::Base.send(:sanitize_sql_like, token) + "%"
      skip_730 = options.include?(:skip_730) && options[:skip_730] == true ? "AND sst.marc_tag != 730" : ""

      query = "SELECT `standard_titles`.`id`, `standard_titles`.`title`, count(standard_titles.id) AS count \
      FROM `standard_titles` 
      JOIN sources_to_standard_titles AS sst on standard_titles.id = sst.standard_title_id \
      WHERE standard_titles.title LIKE (?) \
      #{skip_730} \
      GROUP BY standard_titles.id \
      ORDER BY COUNT(standard_titles.id) DESC LIMIT 20"
      
      return StandardTitle.find_by_sql([query, sanit])
    end

    after_destroy :check_model_errors
    before_create do |item|
      item.user = current_user
    end
    
    def action_methods
      return super - ['new', 'edit', 'destroy'] if is_selection_mode?
      super
    end
    
    def check_model_errors(object)
      return unless object.errors.any?
      flash[:error] ||= []
      flash[:error].concat(object.errors.full_messages)
    end
 
    def permitted_params
      params.permit!
    end
    
    def show
      begin
        @standard_title = StandardTitle.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (StandardTitle #{params[:id]})" }
        return
      end
      @prev_item, @next_item, @prev_page, @next_page, @nav_positions = StandardTitle.near_items_as_ransack(params, @standard_title)
      
      @jobs = @standard_title.delayed_jobs
    end
    
    def index
      @results, @hits = StandardTitle.search_as_ransack(params)
      
      index! do |format|
        @standard_titles = @results
        format.html
      end
    end
    
    # redirect update failure for preserving sidebars
    def update
      update! do |success,failure|
        success.html { redirect_to resource_path(params[:id]) }
        failure.html { redirect_back fallback_location: root_path, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end

      # Run the eventual triggers
      execute_triggers_from_params(params, @standard_title)

    end
    
    # redirect create failure for preserving sidebars
    def create
      create! do |success,failure|
        failure.html { redirect_back fallback_location: root_path, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
    end
    
  end
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], StandardTitle, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :title_eq, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "StandardTitle").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  filter :is_text_with_integer, :label => proc{I18n.t(:filter_is_text)}, as: :select, 
         collection: [["Yes", "is_text:true"],["No", "is_text:false"]]
  
  filter :is_standard_with_integer, :label => proc{I18n.t(:filter_is_standard)}, as: :select, 
         collection: [["Yes", "is_standard:true"],["No", "is_standard:false"]]

  filter :is_additional_with_integer, :label => proc{I18n.t(:filter_is_additional)}, as: :select, 
         collection: [["Yes", "is_additional:true"],["No", "is_additional:false"]]

  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|et| status_tag(et.wf_stage,
      label: I18n.t('status_codes.' + (et.wf_stage != nil ? et.wf_stage : ""), locale: :en))} 
    column (I18n.t :filter_id), :id  
    column ("Type"), :title_type_order, sortable: :title_type_order  do |e| #if current_user.has_any_role?(:editor, :admin)
      active_admin_stored_from_hits(controller.view_assigns["hits"], e, :title_type_order)
    end
    column (I18n.t :filter_title), :title
    column (I18n.t :filter_variants), :alternate_terms
    column (I18n.t :menu_latin), :latin
    column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :src_count_order)
		end
    column (I18n.t :filter_authorities), :referring_objects_order, sortable: :referring_objects_order do |element|
			active_admin_stored_from_hits(controller.view_assigns["hits"], element, :referring_objects_order)
		end
    active_admin_muscat_actions( self )
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
    active_admin_navigation_bar( self )
    render('jobs/jobs_monitor')
    attributes_table do
      row (I18n.t :filter_title) { |r| r.title }
      row (I18n.t :filter_variants) { |r| r.alternate_terms }
      row (I18n.t :menu_latin) { |r| r.latin }
      row (I18n.t :filter_notes) { |r| r.notes }  
      row (I18n.t :filter_owner) { |r| User.find_by(id: r.wf_owner).name rescue r.wf_owner }
    end
    active_admin_embedded_source_list( self, standard_title, !is_selection_mode? )
    active_adnin_create_list_for(self, InventoryItem, standard_title, composer: I18n.t(:filter_composer), title: I18n.t(:filter_title))
    active_adnin_create_list_for(self, Work, standard_title, title: I18n.t(:filter_title), opus: I18n.t(:filter_opus), catalogue: I18n.t(:filter_catalog))

    active_admin_user_wf( self, standard_title )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => standard_title }
  end
  
  sidebar :folders, :only => :show do
    render :partial => "activeadmin/section_sidebar_folder_actions", :locals => { :item => standard_title }
  end

  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      ## Enable the trigger, only for editors
      if current_user.has_any_role?(:editor, :admin)
        f.input :title, :label => (I18n.t :filter_title), input_html: {data: {trigger: triggers_from_hash({save: ["referring_sources", "referring_works"]}) }}
      else
        f.input :title, :label => (I18n.t :filter_title), :input_html => { :disabled => true }
      end
      f.input :latin, :label => (I18n.t :menu_latin) 
      f.input :alternate_terms, :label => (I18n.t :filter_variants)
      f.input :notes, :label => (I18n.t :filter_notes) 
      f.input :wf_stage, :label => (I18n.t :filter_wf_stage)
      f.input :lock_version, :as => :hidden
    end
  end
  
  sidebar :actions, :only => [:edit, :new, :update] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => standard_title }
  end
  
end
