module FolderSidebarHelper
  def folder_bulk_marc_available?(folder)
    return false unless current_user.has_role?(:admin)

    BulkMarc::Configuration.new(folder.folder_model)
    true
  rescue BulkMarc::InvalidOperation
    false
  end

  def folder_owner_change_available?(folder)
    current_user.has_role?(:admin) && folder.owner_change_supported?
  end

  def folder_exports_available?(folder)
    model = folder.folder_model
    controller.respond_to?(:export_folder) && can?(:edit, folder) && model && model.new.respond_to?(:marc_source)
  end
end
