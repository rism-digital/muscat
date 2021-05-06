ActiveAdmin.register CanonicTechnique do

  menu :parent => "indexes_menu", :label => proc {I18n.t(:menu_canonic_techniques)}

  # Remove mass-delete action
  batch_action :destroy, false

  # Remove all action items
  config.clear_action_items!

  breadcrumb do
    active_admin_muscat_breadcrumb
  end

  # See permitted parameters documentation:
  # https://github.com/gregbell/active_admin/blob/master/docs/2-resource-customization.md#setting-up-strong-parameters
  #
  # temporarily allow all parameters
  controller do

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

    def index
      @results, @hits = CanonicTechnique.search_as_ransack(params)

      index! do |format|
        @canonic_techniques = @results
        format.html
      end
    end

    def show
      begin
        @canonic_technique = CanonicTechnique.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        redirect_to admin_root_path, :flash => { :error => "#{I18n.t(:error_not_found)} (Canonic Technique #{params[:id]})" }
        return
      end
      @prev_item, @next_item, @prev_page, @next_page = CanonicTechnique.near_items_as_ransack(params, @canonic_technique)

      @jobs = @canonic_technique.delayed_jobs
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
    job = Delayed::Job.enqueue(ReindexItemsJob.new(CanonicTechnique.find(params[:id]), "referring_sources"))
    redirect_to resource_path(params[:id]), notice: "Reindex Job started #{job.id}"
  end

  ###########
  ## Index ##
  ###########

  filter :canon_type_contains, :label => proc {I18n.t(:filter_canon_type)}, :as => :string
  filter :interval_contains, :label => proc {I18n.t(:filter_interval)}, :as => :string
  filter :interval_direction_contains, :label => proc {I18n.t(:filter_interval_direction)}, :as => :select,
         :collection => [[I18n.t(:filter_above), 'above'], [I18n.t(:filter_below), 'below']]
  filter :temporal_offset_contains, :label => proc {I18n.t(:filter_temporal_offset)}, :as => :string
  filter :offset_units_contains, :label => proc {I18n.t(:filter_offset_units)}, :as => :string

  index :download_links => false do
    selectable_column if !is_selection_mode?
    column (I18n.t :filter_id), :id
    column (I18n.t :display_canon_type) do |canonic_technique|
      "#{canonic_technique.canon_type}: #{canonic_technique.relation_denominator} #{canonic_technique.relation_operator} #{canonic_technique.relation_numerator}"
    end
    # column (I18n.t :display_interval) do |canonic_technique|
    #   "#{canonic_technique.interval} #{canonic_technique.interval_direction}"
    # end
    # column (I18n.t :display_temporal_offset) do |canonic_technique|
    #   offset = "#{canonic_technique.temporal_offset} #{canonic_technique.offset_units}"
    #   if canonic_technique.mensurations.blank?
    #     offset
    #   else
    #     "#{offset} in #{canonic_technique.mensurations}"
    #   end
    # end
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

  ##########
  ## Show ##
  ##########

  show do
    active_admin_navigation_bar( self )
    render('jobs/jobs_monitor')
    attributes_table do
      row (I18n.t :filter_canon_type) { |r| r.canon_type }
      row (I18n.t :filter_relation_numerator) { |r| r.relation_numerator }
      row (I18n.t :filter_relation_operator) { |r| r.relation_operator }
      row (I18n.t :filter_relation_denominator) { |r| r.relation_denominator }
      # Leaving the fields here as comments as there might be potential updates to the following code.
      # row (I18n.t :filter_interval) { |r| r.interval }
      # row (I18n.t :filter_interval_direction) { |r| r.interval_direction }
      # row (I18n.t :filter_temporal_offset) { |r| r.temporal_offset }
      # row (I18n.t :filter_offset_units) { |r| r.offset_units }
      # row (I18n.t :filter_mensurations) { |r| r.mensurations }
    end

    active_admin_embedded_source_list( self, canonic_technique, !is_selection_mode? )
    active_admin_user_wf( self, canonic_technique )
    active_admin_navigation_bar( self )
    active_admin_comments if !is_selection_mode?
  end

  sidebar :actions, :only => :show do
    render :partial => "activeadmin/section_sidebar_show", :locals => { :item => canonic_technique }
  end

  sidebar I18n.t(:search_sources), :only => :show do
    render("activeadmin/src_search") # Calls a partial
  end

  ##########
  ## Edit ##
  ##########

  form do |f|
    f.object.relation_operator = "ex" unless f.object.persisted?
    f.inputs do
      f.input :canon_type, :label => (I18n.t :filter_canon_type), :as => :select,
              :collection => ["canon per tonos", "contrary motion canon (inversion canon)", "continuous canon",
                              "double canon", "enigmatic canon", "interval canon", "invertible canon",
                              "mensuration canon", "octave transposition (parallel)", "parallel canon",
                              "permutation canon", "perpetual canon", "polymorphous canon", "precusor canon",
                              "proportional canon", "puzzle canon", "quadruple canon",
                              "retrograde contrary motion canon", "retrograde motion canon (cancrizans or crab canon)",
                              "resolved canon", "riddle canon", "stacked canon", "triple canon", "unison canon",
                              "verbal canon"]
      f.input :relation_numerator, :label => (I18n.t :filter_relation_numerator), :as => :number
      f.input :relation_operator, :label => (I18n.t :filter_relation_operator), :as => :select,
              :collection => ["ex", "to"]
      f.input :relation_denominator, :label => (I18n.t :filter_relation_denominator), :as => :number
      # Leaving the fields here as comments as there might be potential updates to the following code.
      # f.input :interval, :label => (I18n.t :filter_interval), :as => :select,
      #         :collection => ["unison", "2nd", "3rd", "4th", "5th", "6th", "7th", "8ve", "9th", "10th", "11th", "12th",
      #                         "13th", "14th", "15th", "8ve and 4th", "8ve and 5th", "other"]
      # f.input :interval_direction, :label => (I18n.t :filter_interval_direction), :as => :select,
      #         :collection => ["above", "below"]
      # f.input :temporal_offset, :label => (I18n.t :filter_temporal_offset), :as => :number
      # f.input :offset_units, :label => (I18n.t :filter_offset_units), :as => :select,
      #         :collection => ["semiminim(s)", "minim(s)", "semibreve(s)", "breve(s)", "long(s)", "maxima(e)",
      #                         "tempus", "tempora", "semiquaver(s)", "quaver(s)", "crotchet(s)", "dotted semiminim(s)",
      #                         "dotted minim(s)", "dotted semibreve(s)", "dotted breve(s)", "dotted long(s)", "other"]
      # f.input :mensurations, :label => (I18n.t :filter_mensurations)
      # f.input :lock_version, :as => :hidden
    end
  end

  sidebar :actions, :only => [:edit, :new, :update] do
    render :partial => "activeadmin/section_sidebar_edit", :locals => { :item => canonic_technique }
  end

end