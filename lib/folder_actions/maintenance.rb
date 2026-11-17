require "patches/active_admin/resource_dsl"

module FolderActions
  module Maintenance
    def self.included(dsl)
      dsl.member_action :reindex, method: :post do
        job = Delayed::Job.enqueue(ReindexItemsJob.new(params[:id], Folder, :folder_items))
        redirect_to resource_path(params[:id]), notice: I18n.t(:reindex_job, scope: :folders, id: job.id)
      end
      dsl.member_action :reset_expiration, method: :patch do
        begin
          f = Folder.find(params[:id])
        rescue
          redirect_to collection_path, :flash => {error: I18n.t(:not_found, scope: :folders, id: params[:id])}
          return
        end

        if !can?(:edit, f)
          redirect_to collection_path, :flash => {error: I18n.t(:"active_admin.access_denied.message")}
          return
        end

        # Saving a folder is an explicit renewal. The before_save callback resets
        # its expiration date even when no attributes have changed.
        f.save

        redirect_to resource_path(params[:id]), notice: I18n.t(:"folders.resetted", date: f.delete_date.to_date.to_s)
      end
      dsl.member_action :validate_folder, method: :post do
        begin
          f = Folder.find(params[:id])
        rescue
          # This should really never happen
          redirect_to collection_path, :flash => {error: I18n.t(:not_found, scope: :folders, id: params[:id])}
          return
        end

        if !f.folder_items || f.folder_items.empty?
          redirect_to resource_path(params[:id]), :flash => {error:I18n.t(:folder_empty, scope: :folders)}
          return
        end

        if f.folder_type != "Source"
          redirect_to resource_path(params[:id]), :flash => {error:I18n.t(:folder_not_source, scope: :folders)}
          return
        end

        job = Delayed::Job.enqueue(FolderValidationReportJob.new(f.id, current_user.id))
        redirect_to resource_path(params[:id]), notice: I18n.t(:validation_started, scope: :folders, email: current_user.email, job: job.id)
      end
    end
  end
end
