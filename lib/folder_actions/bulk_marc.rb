require "patches/active_admin/resource_dsl"

module FolderActions
  module BulkMarc
    def self.included(dsl)
      dsl.member_action :bulk_marc_edit, method: :get do
        return head :forbidden unless current_user.has_role?(:admin)

        @folder = Folder.find(params[:id])
        begin
          @bulk_fields = BulkMarcEditor.new(@folder.folder_model).fields
        rescue BulkMarcEditor::InvalidOperation
          return head :unprocessable_entity
        end
        if params[:draft_id].present?
          draft = requested_bulk_marc_draft(@folder)
          return unless draft

          @bulk_operation = draft.operations.first
          @bulk_draft_to_replace = draft.id unless draft.confirmed_at
        end
        @page_title = "Bulk MARC Editor"
      end
      dsl.member_action :preview_bulk_marc_edit, method: :post do
        return head :forbidden unless current_user.has_role?(:admin)

        @folder = Folder.find(params[:id])
        begin
          editor = BulkMarcEditor.new(@folder.folder_model)
        rescue BulkMarcEditor::InvalidOperation
          return head :unprocessable_entity
        end

        begin
          if params[:draft_id].present?
            previous = requested_bulk_marc_draft(@folder)
            return unless previous

            previous.ensure_reviewable!
            operations = previous.operations
          else
            submitted = params.require(:operations)
            unless submitted.is_a?(Array) && submitted.all? { |operation| operation.is_a?(ActionController::Parameters) }
              raise BulkMarcEditor::InvalidOperation, "Invalid operations"
            end
            operations = submitted.map do |operation|
              operation.permit(:action, :tag, :subfield, :target, :value, :old_value, :match_subfield, :match_value).to_h
            end
          end
          if params[:replace_draft_id].present?
            previous = requested_bulk_marc_draft(@folder, :replace_draft_id)
            return unless previous
          end
          size = params[:sample_size] || 10
          @draft, @preview_rows = if previous
            previous.replace_with!(@folder, current_user, operations, sample_size: size)
          else
            BulkMarcEditDraft.prepare(@folder, current_user, operations, sample_size: size)
          end
          @bulk_editor = editor
          @page_title = "Preview bulk MARC edit"
        rescue BulkMarcEditDraft::StalePreview => error
          redirect_to bulk_marc_edit_admin_folder_path(@folder, draft_id: previous&.id), alert: error.message
        rescue BulkMarcEditor::InvalidOperation, ActionController::ParameterMissing => error
          @bulk_fields = editor.fields
          @bulk_operation = operations&.first || {}
          @bulk_draft_to_replace = previous&.id
          @page_title = "Bulk MARC Editor"
          flash.now[:error] = error.message
          render :bulk_marc_edit, status: :unprocessable_entity
        end
      end
      dsl.member_action :run_bulk_marc_edit, method: :post do
        return head :forbidden unless current_user.has_role?(:admin)

        @folder = Folder.find(params[:id])
        params.require(:draft_id)
        draft = requested_bulk_marc_draft(@folder)
        return unless draft

        job = draft.enqueue!(@folder, current_user)
        redirect_to resource_path(@folder), notice: "Bulk MARC edit job started (id: #{job.id})"
      rescue BulkMarcEditDraft::StalePreview => error
        redirect_to bulk_marc_edit_admin_folder_path(@folder, draft_id: draft.id), alert: error.message
      rescue ActionController::ParameterMissing
        head :unprocessable_entity
      end

      dsl.controller do
        private def requested_bulk_marc_draft(folder, key = :draft_id)
          draft = BulkMarcEditDraft.find_by(id: params[key], folder_id: folder.id, requesting_user_id: current_user.id)
          unless draft
            redirect_to bulk_marc_edit_admin_folder_path(folder),
              alert: "This preview is no longer available; generate a new one."
          end
          draft
        end
      end
    end
  end
end
