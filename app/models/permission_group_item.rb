class PermissionGroupItem < ApplicationRecord
  belongs_to :permission_group
  belongs_to :item, polymorphic: true

  validates :item_type,
            presence: true,
            inclusion: { in: PermissionGroup::ITEM_TYPES }
  validates :item_id, presence: true
  validates :item_id, uniqueness: { scope: [:permission_group_id, :item_type] }

  def item_label
    return "#{item_type} ##{item_id}" unless item

    label = if item.respond_to?(:full_name)
      item.full_name
    elsif item.respond_to?(:name)
      item.name
    elsif item.respond_to?(:title)
      item.title
    end

    [item_type, "##{item_id}", label].compact.join(" ")
  end

  def self.ransackable_associations(_auth_object = nil)
    reflections.keys
  end

  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end
end
