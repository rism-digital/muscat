# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module MergeControllerActions
  
  def self.included(dsl)
    dsl.batch_action :merge, confirm: "Are you sure?", if: proc{ current_user.has_role?('admin') || current_user.has_role?('editor') }  do |ids|
      model = self.resource_class
      if ids.size != 2
        redirect_to request.referer, alert: "Too many entries selected!"      
      else  
        collection = model.find(ids)
        if collection.pluck(:wf_stage).sort == ["inprogress", "published"]
          redirect_to request.referer, notice: "Auth merged! #{ids} #{model}"
        else
          redirect_to request.referer, alert: "Not containing published and unpublished items!"      
        end
      end
    end
  end
  
  
end
