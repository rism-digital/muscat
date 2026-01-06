class PullRequest < ApplicationRecord

  include CommentsCleanup

  belongs_to :item, polymorphic: true

  # We cannot directly use composed_of, since we need to filter the marc
  # based on the item type
  def marc
    begin
      klass = "Marc#{item_type}".constantize
    rescue NameError
      raise NameError, "Unknown marc class Marc#{item_type}"
    end

    if klass.respond_to? :record_type
      @marc ||= klass.new(self.marc_source, item.record_type)
    else
      @marc ||= klass.new(self.marc_source)
    end

  end

  def marc=(marc)
    self.marc_source = marc.to_marc
    @marc = marc
  end


  # If we define our own ransacker, we need this
  def self.ransackable_attributes(auth_object = nil)
    column_names + _ransackers.keys
  end

  def self.ransackable_associations(auth_object = nil)
    reflect_on_all_associations.map { |a| a.name.to_s }
  end

end
