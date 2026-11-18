class AddModificationReasonToBulkMarcEditDrafts < ActiveRecord::Migration[7.2]
  def change
    # Existing confirmed jobs may still run with their original generic event.
    # New previews and confirmations require a reason in the application layer.
    add_column :bulk_marc_edit_drafts, :modification_reason, :string, limit: 255
  end
end
