include Triggers

ActiveAdmin.register LiturgicalFeast do
  
  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_liturgical_feasts)}

  # Remove mass-delete action
  batch_action :destroy, false
  include MergeControllerActions

  # Remove all action items
  config.clear_action_items!
  config.per_page = [10, 30, 50, 100]
  
  collection_action :autocomplete_liturgical_feast_name, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :liturgical_feast, :name
    
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
        @liturgical_feast = LiturgicalFeast.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (LiturgicalFeast #{params[:id]})" }
        return
      end
      @prev_item, @next_item, @prev_page, @next_page = LiturgicalFeast.near_items_as_ransack(params, @liturgical_feast)
      
      @jobs = @liturgical_feast.delayed_jobs
    end
    
    def index
      @results, @hits = LiturgicalFeast.search_as_ransack(params)
      
      index! do |format|
        @liturgical_feasts = @results
        format.html
      end
    end
    
    # redirect update failure for preserving sidebars
    def update
      update! do |success,failure|
        success.html { redirect_to collection_path }
        failure.html { redirect_back fallback_location: root_path, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
      # Run the eventual triggers
      execute_triggers_from_params(params, @liturgical_feast)
    end
    
    # redirect create failure for preserving sidebars
    def create
      create! do |success,failure|
        failure.html { redirect_back fallback_location: root_path, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
    end
    
  end
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], LiturgicalFeast, :referring_sources))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :name_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "LiturgicalFeast").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  filter :wf_stage_with_integer, :label => proc {I18n.t(:filter_wf_stage)}, as: :select, 
  collection: proc{[:inprogress, :published, :deleted, :deprecated].collect {|v| [I18n.t("wf_stage." + v.to_s), "wf_stage:#{v}"]}}
 
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_wf_stage) {|feast| status_tag(feast.wf_stage,
      label: I18n.t('status_codes.' + (feast.wf_stage != nil ? feast.wf_stage : ""), locale: :en))} 
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_name), :name
    column (I18n.t :filter_alternate_terms), :alternate_terms
    column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
			all_hits = @arbre_context.assigns[:hits]
			active_admin_stored_from_hits(all_hits, element, :src_count_order)
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
  
  show do
    active_admin_navigation_bar( self )
    render('jobs/jobs_monitor')
    attributes_table do
      row (I18n.t :filter_name) { |r| r.name }
      row (I18n.t :filter_alternate_terms) { |r| r.alternate_terms }
      row (I18n.t :filter_notes) { |r| r.notes } 
    end
    active_admin_embedded_source_list( self, liturgical_feast, !is_selection_mode? )

    active_admin_embedded_link_list(self, liturgical_feast, Work) do |context|
      context.table_for(context.collection) do |cr|
        column (I18n.t :filter_id), :id  
        column (I18n.t :filter_title), :title
        column "Opus", :opus
        column "Catalogue", :catalogue
        if !is_selection_mode?
          context.column "" do |work|
            link_to "View", controller: :works, action: :show, id: work.id
          end
        end
      end
    end

    active_admin_user_wf( self, liturgical_feast )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => liturgical_feast }
  end
  
  sidebar :folders, :only => :show do
    render :partial => "activeadmin/section_sidebar_folder_actions", :locals => { :item => liturgical_feast }
  end

  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      f.input :name, :label => (I18n.t :filter_name), input_html: {data: {trigger: triggers_from_hash({save: ["referring_sources", "referring_works"]}) }}
      f.input :alternate_terms, :label => (I18n.t :filter_alternate_terms)
      f.input :notes, :label => (I18n.t :filter_notes)
      f.input :wf_stage, :label => (I18n.t :filter_wf_stage)
      f.input :lock_version, :as => :hidden
    end
  end
  
  sidebar :actions, :only => [:edit, :new, :update] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => liturgical_feast }
  end
  
end
