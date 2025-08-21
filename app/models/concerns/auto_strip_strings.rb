# Include this is a model to make sure all whitespace leading
# and trailing is always automatically removed

module AutoStripStrings
  extend ActiveSupport::Concern

  included do
    before_save :_auto_strip_string_attributes
  end

  private

  def _auto_strip_string_attributes
    self.class.columns_hash.each do |attr_name, col|
      if col.type == :string
        value = self[attr_name]
        self[attr_name] = value&.strip if value.respond_to?(:strip)
      end
    end
  end
end