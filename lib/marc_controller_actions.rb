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
      # Let it crash is the class is nor fond
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

      @editor_profile = EditorConfiguration.get_applicable_layout @item
      @source = @item
      render :template => 'editor/reload_editor'

    end
  end
  
end