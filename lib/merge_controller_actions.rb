# Override collection_action so it is public
# from activeadmin lib/active_admin/resource_dsl.rb
require 'resource_dsl_extensions.rb'

# Extension module, see
# https://github.com/gregbell/active_admin/wiki/Content-rendering-API
module MergeControllerActions
  
  def self.included(dsl)
    dsl.batch_action :merge, if: proc{ current_user.has_role?('admin')   }  do |ids|
      model = controller_path.classify.gsub(/^.+\:\:/, "")
      redirect_to request.referer, notice: "Auth merged! #{ids} #{model}"
    end
  end
  
  
end
