class PermissionGroupAbility < ApplicationRecord
  belongs_to :permission_group

  before_validation :canonicalize_action

  validates :action,
            presence: true,
            inclusion: { in: PermissionGroup::AVAILABLE_ACTIONS },
            uniqueness: { scope: :permission_group_id }

  def self.ransackable_associations(_auth_object = nil)
    reflections.keys
  end

  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end

  private

  def canonicalize_action
    self.action = PermissionGroup.canonical_action(action)
  end
end
