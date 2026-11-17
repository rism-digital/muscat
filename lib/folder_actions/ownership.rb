require "patches/active_admin/resource_dsl"

module FolderActions
  module Ownership
    def self.included(dsl)
      dsl.member_action :choose_owner, method: :get do
        return head :forbidden unless current_user.has_role?(:admin)

        @folder = Folder.find(params[:id])
        return head :unprocessable_entity unless @folder.owner_change_supported?

        @page_title = I18n.t("folders.change_contents_owner")
      end
      dsl.member_action :change_owner, method: :post do
        return head :forbidden unless current_user.has_role?(:admin)

        folder = Folder.find(params[:id])
        return head :unprocessable_entity unless folder.owner_change_supported?

        new_owner = User.find_by(id: params[:new_owner_id])
        unless new_owner
          redirect_to choose_owner_admin_folder_path(folder), alert: I18n.t("folders.select_valid_owner")
          return
        end

        job = Delayed::Job.enqueue(ChangeOwnerJob.new(
          folder.id, Folder, :folder_items, new_owner.id, requesting_user_id: current_user.id
        ))
        redirect_to resource_path(folder), notice: I18n.t("folders.owner_change_started", id: job.id)
      end
    end
  end
end
