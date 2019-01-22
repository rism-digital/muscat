# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module MergeControllerActions
  
  def self.included(dsl)
    dsl.collection_action :merge, :method => :get do
      model = self.resource_class
      duplicate = model.find(params["duplicate"])
      target = model.find(params["target"])
      duplicate.migrate_to_id(target.id)
      Sunspot.index(duplicate)
      Sunspot.index(target)
      Sunspot.commit
      render json: { result: "SUCCESS"  }
    end
  end
  
  
end
