ActiveAdmin.register StandardTerm do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_subjects)}

  # Remove mass-delete action
  batch_action :destroy, false
  
  # Remove all action items
  config.clear_action_items!
  
  collection_action :autocomplete_standard_term_term, :method => :get

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do
    
    autocomplete :standard_term, :term
    
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
        @standard_term = StandardTerm.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (StandardTerm #{params[:id]})" }
        return
      end
      @prev_item, @next_item, @prev_page, @next_page = StandardTerm.near_items_as_ransack(params, @standard_term)
      
      @jobs = @standard_term.delayed_jobs
    end
    
    def index
      @results, @hits = StandardTerm.search_as_ransack(params)
      
      index! do |format|
        @standard_terms = @results
        format.html
      end
    end
    
    # redirect update failure for preserving sidebars
    def update
      update! do |success,failure|
        success.html { redirect_to collection_path }
        failure.html { redirect_to :back, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
    end
    
    # redirect create failure for preserving sidebars
    def create
      create! do |success,failure|
        failure.html { redirect_to :back, flash: { :error => "#{I18n.t(:error_saving)}" } }
      end
    end
    
  end
  
  member_action :reindex, method: :get do
    job = Delayed::Job.enqueue(ReindexItemsJob.new(StandardTerm.find(params[:id]), "referring_sources"))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end
  
  ###########
  ## Index ##
  ###########
  
  # Solr search all fields: "_equal"
  filter :term_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, 
         collection: proc{Folder.where(folder_type: "StandardTerm").collect {|c| [c.name, "folder_id:#{c.id}"]}}
  
  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id  
    column (I18n.t :filter_term), :term
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
  
  show :title => :term do
    active_admin_navigation_bar( self ) 
    render('jobs/jobs_monitor')
    attributes_table do
      row (I18n.t :filter_term) { |r| r.term }
      row (I18n.t :filter_alternate_terms) { |r| r.alternate_terms }
      row (I18n.t :filter_notes) { |r| r.notes }    
    end
    active_admin_embedded_source_list( self, standard_term, !is_selection_mode? )
    active_admin_user_wf( self, standard_term )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end
  
  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => standard_term }
  end
  
  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end
  
  ##########
  ## Edit ##
  ##########
  
  form do |f|
    f.inputs do
      f.input :term, :label => (I18n.t :filter_term)
      f.input :alternate_terms, :label => (I18n.t :filter_alternate_terms), :input_html => { :rows => 8 }
      f.input :notes, :label => (I18n.t :filter_notes)
      f.input :lock_version, :as => :hidden
    end
  end
  
  sidebar :actions, :only => [:edit, :new, :update] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => standard_term }
  end
  
end
