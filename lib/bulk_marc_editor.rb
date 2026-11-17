# Compatibility entry point shared by controllers, views, jobs, and scripts.
# The underlying services separate configuration, transformation, and previewing.
class BulkMarcEditor
  InvalidOperation = BulkMarc::InvalidOperation

  attr_reader :configuration, :editor

  delegate :model, :marc_config, :editor_profile, :fields, :choices, to: :configuration
  delegate :validate_operations, :apply, to: :editor
  delegate :operation_summary, to: :preview_service

  def initialize(model)
    @configuration = BulkMarc::Configuration.new(model)
    @editor = BulkMarc::Editor.new(configuration)
    @preview_service = BulkMarc::Preview.new(editor)
  end

  def preview(record, operations)
    preview_service.record(record, operations)
  end

  private

  attr_reader :preview_service
end
