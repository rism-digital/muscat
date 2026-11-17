require "patches/active_admin/resource_dsl"

module FolderActions
  module Publishing
    def self.included(dsl)
      dsl.member_action :publish, method: :post do
        job = Delayed::Job.enqueue(PublishItemsJob.new(params[:id], Folder, :folder_items, :publish))
        redirect_to resource_path(params[:id]), notice: I18n.t(:publish_job, scope: :folders, id: job.id)
      end
      dsl.member_action :unpublish, method: :post do
        job = Delayed::Job.enqueue(PublishItemsJob.new(params[:id], Folder, :folder_items, :unpublish))
        redirect_to resource_path(params[:id]), notice: I18n.t(:unpublish_job, scope: :folders, id: job.id)
      end
      dsl.member_action :make_catalogue, method: :post do
        # A bit contorted here: only work_editors can make a Publication into catalogs
        if !can?(:edit, Work) || !can?(:edit, Publication)
          redirect_to collection_path, :flash => {error: I18n.t(:"active_admin.access_denied.message")}
          return
        end

        job = Delayed::Job.enqueue(MakePublicationsCataloguesFromFolder.new(params[:id], params[:work_catalogue_option]))
        redirect_to resource_path(params[:id]), notice: I18n.t(:setting_catalogue_status, scope: :folders, id: job.id)
      end
    end
  end
end
