require "patches/active_admin/resource_dsl"

module FolderActions
  module Exports
    def self.included(dsl)
      dsl.member_action :export_folder, :method => :post do
        begin
          f = Folder.find(params[:id])
        rescue
          # This should really never happen
          redirect_to collection_path, :flash => {error: I18n.t(:not_found, scope: :folders, id: params[:id])}
          return
        end

        model = f.folder_model

        if !model
          redirect_to resource_path(params[:id]), :flash => {error: "Folder type is not supported"}
          return
        end

        if !f.folder_items || f.folder_items.empty?
          redirect_to resource_path(params[:id]), :flash => {error:I18n.t(:folder_empty, scope: :folders)}
          return
        end

        if f.folder_items.count > 25000
          redirect_to resource_path(params[:id]), :flash => {error: I18n.t(:export_limit, scope: :folders, max: 25000, count: f.folder_items.count)}
          return
        end

        format = :xml
        if params.include?(:type)
          format = :xml if params[:type] == "xml"
          format = :csv if params[:type] == "csv"
          format = :raw if params[:type] == "raw"
          format = :raw_holdings if params[:type] == "raw_holdings"
        end

        job = Delayed::Job.enqueue(ExportRecordsJob.new(:folder, {id: params[:id], email: current_user.email, format: format, model: model}))
        redirect_to resource_path(params[:id]), notice: I18n.t(:export_started, scope: :folders, email: current_user.email, job: job.id)
      end
    end
  end
end
