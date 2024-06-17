module SectionSidebarFolderActionsHelper
  def define_attributes_for_section_sidebar_folder_actions(item)
    @model_underscore_downcase = item.class.to_s.underscore.downcase
    compatible_folders = Folder.where(folder_type: item.class)

    # Make sure we can manage the folder
    list = compatible_folders.to_a.reject {|f| cannot?(:manage, f) ? true : false}
    
    @folders_with_this_item = compatible_folders.where(id: item.folder_items.pluck(:folder_id)).to_a.reject {|f| cannot?(:manage, f) ? true : false}
    @folders_without_this_item = list - @folders_with_this_item
  end
end
