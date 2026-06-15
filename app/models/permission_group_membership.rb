class PermissionGroupMembership < ApplicationRecord
  belongs_to :permission_group
  belongs_to :user

  validates :user_id, uniqueness: { scope: :permission_group_id }

  def self.ransackable_associations(_auth_object = nil)
    reflections.keys
  end

  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end
end
