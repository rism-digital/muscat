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
        collection = model.where(id: ids).order(:wf_stage)
        if collection.pluck(:wf_stage) != ["inprogress", "published"]
          redirect_to request.referer, alert: "Not containing published and unpublished items!"      
        else
          duplicate, target = collection
          duplicate.migrate_to_id(target.id)
          Sunspot.index(duplicate)
          Sunspot.index(target)
          Sunspot.commit
          redirect_to request.referer, notice: "#{model} ID#{duplicate.id} successfully merged into ID#{target.id}!"
        end
      end
    end
  end
  
  
end
