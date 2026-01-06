# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'patches/active_admin/resource_dsl.rb'
require 'patches/active_admin/resource_controller.rb'
include Triggers

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module MarcControllerActions

  def self.included(dsl)
    # THIS IS OVERRIDEN from resource_dsl_extensions.rb
    
    ##########
    ## Save ##
    ##########
    
    dsl.collection_action :marc_editor_save, :method => :post do

      #Get the model we are working on
      model = self.class.resource_class

      marc_hash = JSON.parse params[:marc]
        
      # This is the tricky part. Get the MARC subclass
      # e.g. MarcSource or MarcPerson
      classname = "Marc" + model.to_s
      # Let it crash is the class is not fond
      dyna_marc_class = Kernel.const_get(classname)
      
      new_marc = dyna_marc_class.new()
      new_marc.load_from_hash(marc_hash, user: current_user)

      # @item is used in the Marc Editor
      @item = nil
      if new_marc.get_id != "__TEMP__" 
        # To get the ID for holdings
        if params[:controller] == "admin/holdings" || params[:controller] == "admin/inventory_items"
          @item = model.find(params[:id])
        else
          @item = model.find(new_marc.get_marc_source_id)
        end
      end

      if !@item
        @item = model.new
        @item.user = current_user
        
        # This is a special case for Holdings
        # in which the link is created out of marc
        # For now hardcode, when needed :parent_object_type
        # will have the proper model
        # PLEASE NOTE: The existence of this object should
        # be checked beforehand in the :new controller action
        if params.include?(:parent_object_id)
          source = Source.find(params[:parent_object_id])
          @item.source = source
        end
        
      end
      @item.marc = new_marc
      @item.lock_version = params[:lock_version]
      
      @item.record_type = params[:record_type] if (@item.respond_to? :record_type)
      
      # Some housekeeping, change  status
      # Also make sure that the status is not something creative
      if params[:record_status].present? && 
        %w[published inprogress].include?(params[:record_status]) &&
        current_user.has_any_role?(:cataloger, :editor, :admin)

        new_status = params[:record_status]

        if current_user.has_any_role?(:editor, :admin)
          # Editors/Admins can always change status
          @item.wf_stage = new_status

        elsif current_user.has_role?(:cataloger)
          # Cataloguers can always publish
          if new_status == "published"
            @item.wf_stage = new_status

          # Cataloguers can unpublish only if record is <10 min old
          elsif @item.wf_stage == "published" && !@item.new_record? && @item.created_at > 10.minutes.ago
            @item.wf_stage = new_status
          end
        end
      end

      # Change owner, if you are authorized
      if params.has_key?(:record_owner) &&
        (current_user.has_role?(:editor) || current_user.has_role?(:admin))
        new_user = User.find(params[:record_owner]) rescue new_user = nil
        @item.user = new_user if new_user
      end
      
      if params.has_key?(:record_audit) &&
        (current_user.has_role?(:cataloger) || current_user.has_role?(:editor) || current_user.has_role?(:admin))
        @item.wf_audit = params[:record_audit]
      end

      if params.has_key?(:work_catalogue_status) && @item.is_a?(Publication) &&
        (can?(:edit, Work) || current_user.has_role?(:editor) || current_user.has_role?(:admin))
        @item.work_catalogue = params[:work_catalogue_status]
        ap params[:work_catalogue_status]
      end

      # Set the user name to the model class variable
      # This is used by the VersionChecker module to see if we want a version to be stored
      @item.last_user_save = current_user.name

      @item.save

      flash[:notice] = "#{model.to_s} #{@item.id} was successfully saved." 
      
      # Send the validation notification
      SourceValidationNotifications.mail_validation(@item).deliver_now if RISM::SEND_VALIDATION_NOTIFICATIONS && @item.is_a?(Source)
      #PublicationValidationNotifications.mail_validation(@item).deliver_now if @item.is_a?(Publication)
      
      # if we arrived here it means nothing crashed
      # Rejoice! and launch the background jobs
      # if any
      execute_triggers_from_params(params, @item)
      # Now run the global ones as specified in the FormOptions
      execute_global_triggers(@item)

      # build the dynamic model path
      
      # Redirect decides if we ar reloading the editor or redirecting
      # to the index page
      redirect = params.include?(:redirect) ? params[:redirect] : false

      if redirect == "true"
        model_for_path = self.class.resource_class.to_s.underscore.downcase
        if (model_for_path == "holding") && params.include?(:parent_object_id)
            path = admin_source_path(params[:parent_object_id])
        else
          link_function = "admin_#{model_for_path}_path"
          path =  send(link_function, @item.id) #admin_sources_path
        end
      else
        model_for_path = self.class.resource_class.to_s.underscore.downcase
        link_function = "edit_admin_#{model_for_path}_path"
        path =  send(link_function, @item.id) #admin_edit_source_path(@item.id)
      end

      respond_to do |format|
        format.js { render :json => { :redirect => path }.to_json }
      end
    end
  
    #############
    ## Preview ##
    #############
    
    dsl.collection_action :marc_editor_preview, :method => :post do
      
      #Get the model we are working on
      model = self.class.resource_class

      marc_hash = JSON.parse params[:marc]
      
      # This is the tricky part. Get the MARC subclass
      # e.g. MarcSource or MarcPerson
      classname = "Marc" + model.to_s
      # Let it crash is the class is not fond
      dyna_marc_class = Kernel.const_get(classname)
      
      new_marc = dyna_marc_class.new()
      # Load marc, do not resolve externals
      new_marc.load_from_hash(marc_hash)

      @item = model.new
      @item.marc = new_marc
      
      @item.set_object_fields
      @item.generate_id if @item.respond_to?(:generate_id)

      @editor_profile = EditorConfiguration.get_show_layout @item
     
      render :template => 'marc_show/show_preview'
    end

    ###################
    ## Summary show ##
    ###################
    
    dsl.collection_action :marc_editor_summary_show, :method => :post do
      
      @item = Source.find( params[:object_id] )
      
      @item.marc.load_source(true)
      @editor_profile = EditorConfiguration.get_show_layout @item
      
      render :template => 'marc_show/show_preview'
    end
    
    ##################
    ## View version ##
    ##################
    
    dsl.collection_action :marc_editor_version, :method => :post do
      
      begin
        version = PaperTrail::Version.find( params[:version_id] )
      rescue ActiveRecord::RecordNotFound
        # Can happen, if people have two windows open
        redirect_to admin_root_path, :flash => { :error => "Selected version does not appear to exist anymore" }
        return
      end
      @item = version.reify
      
      # Do not resolve external since we might foreign object that might have been deleted since then
      @item.marc.load_source(false)
      @editor_profile = EditorConfiguration.get_show_layout @item
      
      render :template => 'marc_show/show_preview'
    end
  
    ##################
    ## Diff version ##
    ##################
    
    dsl.collection_action :marc_editor_version_diff, :method => :post do
      
      begin
        version = PaperTrail::Version.find( params[:version_id] )
      rescue ActiveRecord::RecordNotFound
        # Can happen, if people have two windows open
        redirect_to admin_root_path, :flash => { :error => "Selected version does not appear to exist anymore" }
        return
      end
      
      @item = version.item_type.singularize.classify.constantize.new
      tags, wf_stages = VersionChecker.get_diff_with_next(params[:version_id])
      @item.marc.load_from_array(tags)
      @editor_profile = EditorConfiguration.get_show_layout @item
      
      # Parameter for using diff partials
      @diff = true
      
      # Did the wf_stage change? if so we have a dedicated partial
      if wf_stages[0] != wf_stages[1]
        @wf_stages = wf_stages
      else
        @wf_stages = false
      end

      render :template => 'marc_show/show_preview'
    end
    
    #####################
    ## Restore version ##
    #####################
    
    dsl.member_action :marc_restore_version, method: :put do
      
      if !(current_user.has_role?(:admin) || current_user.has_role?(:editor))
        redirect_to admin_root_path, :flash => { :error => I18n.t("active_admin.access_denied.message") }
        return
      end

      #Get the model we are working on
      model = self.class.resource_class
      @item = model.find(params[:id])
      
      begin
        version = PaperTrail::Version.find( params[:version_id] )
      rescue ActiveRecord::RecordNotFound
        # Can happen, if people have two windows open
        redirect_to admin_root_path, :flash => { :error => "Selected version does not appear to exist anymore" }
        return
      end
    
      old_item = version.reify

      classname = "Marc" + model.to_s
      dyna_marc_class = Kernel.const_get(classname)
      old_item.marc.load_source(false)
      
      new_marc = nil
      if @item.respond_to?(:record_type)
        new_marc = dyna_marc_class.new(old_item.marc.to_marc, @item.record_type)
      else
        new_marc = dyna_marc_class.new(old_item.marc.to_marc)
      end
      new_marc.load_source(false)
      new_marc.import

      @item.marc = new_marc
      @item.paper_trail_event = "restore"
      @item.save
      
      redirect_to resource_path(@item), notice: "Correctly restored to version #{params[:version_id]}"
    end
  
    ####################
    ## Delete version ##
    ####################
    
    dsl.member_action :marc_delete_version, method: :put do
      
      if !current_user.has_role?(:admin)
        redirect_to admin_root_path, :flash => { :error => I18n.t("active_admin.access_denied.message") }
        return
      end

      begin
        version = PaperTrail::Version.find( params[:version_id] )
      rescue ActiveRecord::RecordNotFound
        # Can happen, if people have two windows open
        redirect_to admin_root_path, :flash => { :error => "Selected version does not appear to exist anymore" }
        return
      end
      @item = version.reify
      version.delete
      
      # Parameter for showing history in editor
      @show_history = true

      model_for_path = self.class.resource_class.to_s.underscore.downcase
      link_function = "edit_admin_#{model_for_path}_path"
      redirect_to send(link_function, @item.id, {:show_history => true}), notice: "Deleted snapshot #{params[:version_id]}"
    end
  
    #############
    ##Validate ##
    #############
    
    dsl.collection_action :marc_editor_validate, :method => :post do
      #Get the model we are working on
      model = self.class.resource_class

      marc_hash = JSON.parse params[:marc]
      current_user = User.find(params[:current_user])
      
      # This is the tricky part. Get the MARC subclass
      # e.g. MarcSource or MarcPerson
      classname = "Marc" + model.to_s
      # Let it crash is the class is not fond
      dyna_marc_class = Kernel.const_get(classname)
      
      new_marc = dyna_marc_class.new()
      # Load marc, do not resolve externals
      new_marc.load_from_hash(marc_hash, user: current_user) # -> revert to old behaviour, dry_run: true)

      @item = model.new
      @item.marc = new_marc
      
      @item.set_object_fields
      @item.generate_id if @item.respond_to?(:generate_id)
      @item.record_type = params[:record_type] if (@item.respond_to? :record_type)
      
      validator = MarcValidator.new(@item, current_user)
      validator.validate_tags
      #validator.validate_links
      validator.validate_unknown_tags
      validator.validate_server_side
      if validator.has_errors
        render json: {status: validator.to_s(translate: true)}
      else
        render json: {status: I18n.t("validation.correct")}
      end
    end

    dsl.collection_action :marc_editor_create_pull_request, :method => :post do
      # Get the model we are working on
      model = self.class.resource_class  
      marc_klass = "Marc#{model.to_s}".constantize 

      # Parse and create new marc
      marc_hash = JSON.parse(params[:marc])
      new_marc = marc_klass.new()
      new_marc.load_from_hash(marc_hash, user: current_user)

      # Find the item we are referring to...
      item = model.find(params[:id])

      message = params.fetch(:message, "")

      pl = PullRequest.new(item: item, marc_source: new_marc.to_marc, message: message )
      pl.save

      respond_to do |format|
        format.js { render :json => { :redirect => "/admin/pull_requests" }.to_json }
      end

    end
 
  end
  
end
