# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module MarcControllerActions
  
  
  
  def self.included(dsl)
    # THIS IS OVERRIDEN from resource_dsl_extensions.rb
    dsl.collection_action :marc_editor_save, :method => :post do
      
      #Get the model we are working on
      model = self.resource_class

      marc_hash = JSON.parse params[:marc]
      
      # This is the tricky part. Get the MARC subclass
      # e.g. MarcSource or MarcPerson
      classname = "Marc" + model.to_s
      # Let it crash is the class is not fond
      dyna_marc_class = Kernel.const_get(classname)
      
      new_marc = dyna_marc_class.new()
      new_marc.load_from_hash(marc_hash)

      # @item is used in the Marc Editor
      @item = nil
      if new_marc.get_id != "__TEMP__" 
        @item = model.find(new_marc.get_marc_source_id)
      end

      if !@item
        @item = model.new
      end
      @item.marc = new_marc

      @item.save
      flash[:notice] = "#{model.to_s} #{@item.id} was successfully saved." 

     # @editor_profile = EditorConfiguration.get_applicable_layout @item
     # @source = @item
     
     # build the dynamic model path
      model_for_path = self.resource_class.to_s.underscore.downcase
      link_function = "edit_#{model_for_path}_path"
     
      path =  send(link_function, @item.id) #edit_source_path(@item.id)

      respond_to do |format|
        format.js { render :json => { :redirect => path }.to_json }
      end

      #render :template => 'editor/reload_editor'

    end
    
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
      new_marc.load_from_hash(marc_hash)

      @item = model.new
      @item.marc = new_marc
      
      @item.set_object_fields
      @item.generate_id if @item.respond_to?(:generate_id)

      @editor_profile = EditorConfiguration.get_show_layout @item
     
      render :template => 'marc_show/show_preview'

    end
    
    # This can be used to add a button in the title bar
    #dsl.action_item :only => [:edit, :new] do
    #    link_to('View on site', "javascript:marc_editor_send_form('marc_editor_panel','marc_editor_panel', 0, '#{self.resource_class.to_s.pluralize.downcase}')")
    #end
  
  end
  
  
end