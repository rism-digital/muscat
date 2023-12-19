module SectionSidebarFolderActionsHelper
  def define_attributes_for_section_sidebar_folder_actions(item)
    @model_underscore_downcase = item.class.to_s.underscore.downcase
    compatible_folders = Folder.where(folder_type: item.class)
    @folders_with_this_item = compatible_folders.where(id: item.folder_items.pluck(:folder_id))
    @folders_without_this_item = compatible_folders - @folders_with_this_item
  end
end
