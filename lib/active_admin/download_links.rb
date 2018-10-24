# Monkey patch to remove the download links 
# But still have the .xml download in the show action
# see https://github.com/rism-ch/muscat/issues/587
# and https://github.com/activeadmin/activeadmin/blob/master/lib/active_admin/resource_controller.rb#L52

# This overrides restrict_format_access! so that if the controller action
# is not show it will call the original version (and fail). This way we
# can have the overridden .xml download for a single item without the whole list
module ActiveAdmin
  class ResourceController
    alias_method :"old_restrict_format_access!", :"restrict_format_access!"
    
    def restrict_format_access!
      if action_name = "show" && request.format.xml?
        true
      else
        old_restrict_format_access!
      end
    end
  end
end
