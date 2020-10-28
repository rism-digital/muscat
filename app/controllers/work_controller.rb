include Triggers
require 'sunspot_extensions.rb'

class WorkController < ApplicationController
  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller
  include Blacklight::Catalog

  DEFAULT_FACET_LIMIT = 20

  # config.clear_action_items!
  # config.per_page = [10, 30, 50, 100]

  # menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_works)}, :if => proc{ can? :edit, Work  }

  # Remove mass-delete action
  # batch_action :destroy, false
  # include MergeControllerActions

  # collection_action :autocomplete_work_title, :method => :get
  #
  # collection_action :viaf, method: :get do
  #   respond_to do |format|
  #     format.json { render json: Work.get_viaf(params[:viaf_input])  }
  #   end
  # end


  # breadcrumb do
  #   active_admin_muscat_breadcrumb
  # end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters


  # autocomplete :work, :title, :extra_data => [:title], :string_boundary => true

  # after_destroy :check_model_errors
  # before_create do |item|
  #   item.user = current_user
  # end
  #
  # def action_methods
  #   return super - ['new', 'edit', 'destroy'] if is_selection_mode?
  #   super
  # end
  #
  # def check_model_errors(object)
  #   return unless object.errors.any?
  #   flash[:error] ||= []
  #   flash[:error].concat(object.errors.full_messages)
  # end

  # def permitted_params
  #   params.permit!
  # end
  #
  # def edit
  #   @item = Work.find(params[:id])
  #   @show_history = true if params[:show_history]
  #   @editor_profile = EditorConfiguration.get_default_layout @item
  #   @page_title = "#{I18n.t(:edit)} #{@editor_profile.name} [#{@item.id}]"
  #
  #   @restricted=""
  # end

  def admin_embedded_source_list(contextt, item, enable_view_src = true)
    # The columns should be the same for every list in every page!
    admin_embedded_link_list(contextt, item, Source) do |context|
      context.table_for(context.collection) do |cr|
        context.column "id", :id
        context.column (I18n.t :filter_composer), :composer
        context.column (I18n.t :filter_std_title), :std_title
        context.column (I18n.t :filter_title), :title
        context.column (I18n.t :filter_lib_siglum), :lib_siglum
        context.column (I18n.t :filter_shelf_mark), :shelf_mark
        if enable_view_src
          context.column "" do |source|
            link_to "View", controller: :sources, action: :show, id: source.id
          end
        end
      end
    end
  end


  def admin_embedded_link_list(context, item, link_class, panel_title = nil, &block)
    current_page_name = link_class.to_s.downcase + "_list_page"
    current_page = params[current_page_name]
    if link_class == Source && item.respond_to?("referring_sources") && item.respond_to?("referring_holdings")
      c = Source.where(id: item.referring_sources.ids).or(Source.where(id: item.referring_holdings.pluck(:source_id)))
    elsif link_class == Source && item.respond_to?("referring_sources") && item.is_a?(Institution)
      c = Source.where(id: item.referring_sources.ids).or(Source.where(id: item.holdings.pluck(:source_id)))
    else
      c = item.send("referring_" + link_class.to_s.pluralize.underscore)
    end
    # do not display the panel if no source attached
    return if c.empty?
    panel_title = I18n.t(:refers_to_this, model_from: link_class.model_name.human(count: 2), model_to: item.model_name.human) if !panel_title

    context.panel panel_title, :class => "muscat_panel"  do
      context.paginated_collection(c.page(current_page).per(10), param_name: current_page_name,  download_links: false) do
        yield(context)
      end
    end
  end

  def show
    begin
      @item = @work = Work.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Work #{params[:id]})" }
      return
    end
    @editor_profile = EditorConfiguration.get_show_layout @work
    @prev_item, @next_item, @prev_page, @next_page = Work.near_items_as_ransack(params, @work)

    @jobs = @work.delayed_jobs
    # @item = @arbre_context.assigns[:item]
    # if @item.marc_source == nil
    #   render :partial => "marc/missing"
    # else
    #   render :partial => "marc/show"
    # end

    work = @work;
    @is_selection_mode = false ;


    # admin_embedded_source_list( @contextt, work, !is_selection_mode? )


    # respond_to do |format|
    #   format.html

    #   format.xml { render :xml => @item.marc.to_xml(@item.updated_at, @item.versions, :partial => "marc/show") }
    # end
  end

  def index
    # ToDo:
    # IF there is no index, set it to page no 1
    #
    # @results, @hits = Work.search_as_ransack(params)
    @results, @hits = Work.search_as_ransack(params)
    @works = @results


    @no_of_sources = {}

    @works.each_with_index  do |each_work, i |
      @query = "select count(*) from sources_to_works where work_id = '"+ each_work.id.to_s+ "'";
      @sources_count = Work.count_by_sql(@query);
      @no_of_sources[each_work.id.to_i]= @sources_count;
    end
    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @works }
      format.js
    end

    # index! do |format|
    #   @works = @results
    #   format.html
    # end
  end

  # show :title => proc{ active_admin_auth_show_title( @item.title, nil, @item.id) } do
  #   # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
  #   active_admin_navigation_bar( self )
  #
  #   render('jobs/jobs_monitor')
  #
  #   @item = @arbre_context.assigns[:item]
  #   if @item.marc_source == nil
  #     render :partial => "marc/missing"
  #   else
  #     render :partial => "marc/show"
  #   end
  #   active_admin_embedded_source_list( self, work, !is_selection_mode? )
  #   active_admin_digital_object( self, @item ) if !is_selection_mode?
  #   active_admin_user_wf( self, work )
  #   active_admin_navigation_bar( self )
  #   active_admin_comments if !is_selection_mode?
  # end
  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  # filter :title_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  # filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select, collection: proc{Folder.where(folder_type: "Work").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  # index :download_links => false do
  #   selectable_column if !is_selection_mode?
  #   column (I18n.t :filter_wf_stage) {|work| status_tag(work.wf_stage,label: I18n.t('status_codes.' + (work.wf_stage != nil ? work.wf_stage : ""), locale: :en))}
  #   column (I18n.t :filter_id), :id
  #   column (I18n.t :filter_title), :title
  #   column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
  #     all_hits = @arbre_context.assigns[:hits]
  #     # active_admin_stored_from_hits(all_hits, element, :src_count_order)
  #   end
    # active_admin_muscat_actions( self )
  # end

  # sidebar :actions, :only => :index do
  #   render :partial => "activeadmin/filter_workaround"
  #   render :partial => "activeadmin/section_sidebar_index"
  # end

  # Include the folder actions
  # include FolderControllerActions

  ##########
  ## Show ##
  ##########

  # show :title => proc{ active_admin_auth_show_title( @item.title, nil, @item.id) } do
  #   # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
  #   # active_admin_navigation_bar( self )
  #
  #   render('jobs/jobs_monitor')
  #
  #   @item = @arbre_context.assigns[:item]
  #   if @item.marc_source == nil
  #     render :partial => "marc/missing"
  #   else
  #     render :partial => "marc/show"
  #   end
  #   # active_admin_embedded_source_list( self, work, !is_selection_mode? )
  #   # active_admin_digital_object( self, @item ) if !is_selection_mode?
  #   # active_admin_user_wf( self, work )
  #   # active_admin_navigation_bar( self )
  #   # active_admin_comments if !is_selection_mode?
  # end
  #
  # sidebar :actions, :only => :show do
  #   render :partial => "activeadmin/section_sidebar_show", :locals => { :item => work }
  # end
  # def new
  #   @work = Work.new
  #
  #   new_marc = MarcWork.new(File.read("#{Rails.root}/config/marc/#{RISM::MARC}/work/default.marc"))
  #   new_marc.load_source false # this will need to be fixed
  #   @work.marc = new_marc
  #
  #   @editor_profile = EditorConfiguration.get_default_layout @work
  #   # Since we have only one default template, no need to change the title
  #   #@page_title = "#{I18n.t('active_admin.new_model', model: active_admin_config.resource_label)} - #{@editor_profile.name}"
  #   #To transmit correctly @item we need to have @source initialized
  #   @item = @work
  # end



  # Include the MARC extensions
  # include MarcControllerActions

  # member_action :reindex, method: :get do
  #   job = Delayed::Job.enqueue(ReindexItemsJob.new(Work.find(params[:id]), "referring_sources"))
  #   redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  # end

  ###########
  ## Index ##
  ###########

  # Solr search all fields: "_equal"
  # filter :title_equals, :label => proc {I18n.t(:any_field_contains)}, :as => :string
  # This filter passes the value to the with() function in seach
  # see config/initializers/ransack.rb
  # Use it to filter sources by folder
  # filter :id_with_integer, :label => proc {I18n.t(:is_in_folder)}, as: :select,
  #        collection: proc{Folder.where(folder_type: "Work").collect {|c| [c.name, "folder_id:#{c.id}"]}}

  # index :download_links => false do
  #   selectable_column if !is_selection_mode?
  #   column (I18n.t :filter_wf_stage) {|work| status_tag(work.wf_stage, label: I18n.t('status_codes.' + (work.wf_stage != nil ? work.wf_stage : ""), locale: :en))}
  #   column (I18n.t :filter_id), :id
  #   column (I18n.t :filter_title), :title
  #   column (I18n.t :filter_sources), :src_count_order, sortable: :src_count_order do |element|
  #     # all_hits = @arbre_context.assigns[:hits]
  #     # # active_admin_stored_from_hits(all_hits, element, :src_count_order)
  #   end
  #   # active_admin_muscat_actions( self )
  # end

  # sidebar :actions, :only => :index do
  #   render :partial => "activeadmin/filter_workaround"
  #   render :partial => "activeadmin/section_sidebar_index"
  # end

  # Include the folder actions
  # include FolderControllerActions
  #
  # ##########
  # ## Show ##
  # ##########
  #
  # show :title => proc{ active_admin_auth_show_title( @item.title, nil, @item.id) } do
  #   # @item retrived by from the controller is not available there. We need to get it from the @arbre_context
  #   active_admin_navigation_bar( self )
  #
  #   render('jobs/jobs_monitor')
  #
  #   @item = @arbre_context.assigns[:item]
  #   if @item.marc_source == nil
  #     render :partial => "marc/missing"
  #   else
  #     render :partial => "marc/show"
  #   end
  #   active_admin_embedded_source_list( self, work, !is_selection_mode? )
  #   active_admin_digital_object( self, @item ) if !is_selection_mode?
  #   active_admin_user_wf( self, work )
  #   active_admin_navigation_bar( self )
  #   active_admin_comments if !is_selection_mode?
  # end
  #
  # sidebar :actions, :only => :show do
  #   render :partial => "activeadmin/section_sidebar_show", :locals => { :item => work }
  # end
  #
  #
  # ##########
  # ## Edit ##
  # ##########
  #
  # form :partial => "editor/edit_wide"
  #
  # sidebar :sections, :only => [:edit, :new, :update] do
  #   render("editor/section_sidebar") # Calls a partial
  # end

end
