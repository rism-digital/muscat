# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

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
      model = self.resource_class

      # Set the user name to the model class variable
      # This is used by the VersionChecker module to see if we want a version to be stored
      model.last_user_save = current_user.name
      model.last_event_save = "update"

      marc_hash = JSON.parse params[:marc]
      
      # This is the tricky part. Get the MARC subclass
      # e.g. MarcSource or MarcPerson
      classname = "Marc" + model.to_s
      # Let it crash is the class is not fond
      dyna_marc_class = Kernel.const_get(classname)
      
      new_marc = dyna_marc_class.new()
      new_marc.load_from_hash(marc_hash, current_user)

      # @item is used in the Marc Editor
      @item = nil
      if new_marc.get_id != "__TEMP__" 
        @item = model.find(new_marc.get_marc_source_id)
      end

      if !@item
        @item = model.new
        @item.user = current_user
      end
      @item.marc = new_marc
      @item.lock_version = params[:lock_version]

      @item.save
      flash[:notice] = "#{model.to_s} #{@item.id} was successfully saved." 
      
      # Reset the user name and the event to nil for next time
      model.last_user_save = nil
      model.last_event_save = nil
     
      # build the dynamic model path
      
      # Redirect decides if we ar reloading the editor or redirecting
      # to the index page
      redirect = params.include?(:redirect) ? params[:redirect] : false

      if redirect == "true"
        model_for_path = self.resource_class.to_s.underscore.pluralize.downcase
        link_function = "admin_#{model_for_path}_path"
        path =  send(link_function) #admin_sources_path
      else
        model_for_path = self.resource_class.to_s.underscore.downcase
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
      model = self.resource_class

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
  
    ##########
    ## Help ##
    ##########
    
    dsl.collection_action :marc_editor_help, :method => :post do

      help = params[:help]
      help_fname = EditorConfiguration.get_help_fname(help)
      @help_title = params[:title]
      @help_text = IO.read("#{Rails.root}/public/#{help_fname}")
     
      render :template => 'editor/show_help'
    end
  
    ##################
    ## View version ##
    ##################
    
    dsl.collection_action :marc_editor_version, :method => :post do
      
      version = PaperTrail::Version.find( params[:version_id] )
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
      
      version = PaperTrail::Version.find( params[:version_id] )

      @item = version.item_type.singularize.classify.constantize.new
      @item.marc.load_from_array( VersionChecker.get_diff_with_next( params[:version_id] ) )
      @editor_profile = EditorConfiguration.get_show_layout @item
      
      # Parameter for using diff partials
      @diff = true
      
      render :template => 'marc_show/show_preview'
    end
    
    #####################
    ## Restore version ##
    #####################
    
    dsl.member_action :marc_restore_version, method: :put do
      
      #Get the model we are working on
      model = self.resource_class
      @item = model.find(params[:id])
      
      version = PaperTrail::Version.find( params[:version_id] )
      old_item = version.reify

      classname = "Marc" + model.to_s
      dyna_marc_class = Kernel.const_get(classname)
      new_marc = dyna_marc_class.new(old_item.marc.to_marc)
      
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
      
      version = PaperTrail::Version.find( params[:version_id] )
      @item = version.reify
      version.delete
      
      # Parameter for showing history in editor
      @show_history = true

      model_for_path = self.resource_class.to_s.underscore.downcase
      link_function = "edit_admin_#{model_for_path}_path"
      redirect_to send(link_function, @item.id, {:show_history => true}), notice: "Deleted snapshot #{params[:version_id]}"
    end
  
  end
  
end