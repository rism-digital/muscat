class PermissionGroup < ApplicationRecord
  ITEM_TYPES = %w[
    DigitalObject
    Folder
    Holding
    Institution
    InventoryItem
    LiturgicalFeast
    Person
    Place
    Publication
    Source
    StandardTerm
    StandardTitle
    Work
    WorkNode
  ].freeze

  AVAILABLE_ACTIONS = %w[
    read
    update
    destroy
    publish
    unpublish
  ].freeze

  ACTION_ALIASES = {
    "delete" => "destroy",
    "edit" => "update",
    "index" => "read",
    "show" => "read"
  }.freeze

  ACTION_LABELS = {
    "read" => "read",
    "update" => "edit",
    "destroy" => "destroy",
    "publish" => "publish",
    "unpublish" => "unpublish"
  }.freeze

  belongs_to :owner_user, class_name: "User", optional: true
  has_many :permission_group_memberships, dependent: :destroy
  has_many :users, through: :permission_group_memberships
  has_many :permission_group_items, dependent: :destroy
  has_many :permission_group_abilities, dependent: :destroy

  accepts_nested_attributes_for :permission_group_items,
                                allow_destroy: true,
                                reject_if: :permission_group_item_blank?

  scope :active, -> { where(active: true) }

  validates :name, presence: true
  validate :action_names_are_allowed

  after_save :save_action_names, if: :action_names_changed?

  def self.canonical_action(action)
    action_name = action.to_s
    ACTION_ALIASES.fetch(action_name, action_name)
  end

  def self.action_label(action)
    ACTION_LABELS.fetch(canonical_action(action), action.to_s)
  end

  def self.grants_for(user)
    return {} unless user&.persisted?

    rows = PermissionGroupItem
      .joins(permission_group: [:permission_group_abilities, :permission_group_memberships])
      .merge(PermissionGroup.active)
      .where(permission_group_memberships: { user_id: user.id })
      .distinct
      .pluck(:item_type, "permission_group_abilities.action", :item_id)

    rows.each_with_object({}) do |(item_type, action, item_id), grants|
      key = [item_type, action.to_sym]
      grants[key] ||= []
      grants[key] << item_id
    end
  end

  def action_names
    if action_names_changed?
      @action_names
    else
      permission_group_abilities.map(&:action)
    end
  end

  def action_names=(values)
    @action_names = Array(values).reject(&:blank?).map do |value|
      self.class.canonical_action(value)
    end.uniq
  end

  def action_labels
    action_names.map { |action| self.class.action_label(action) }
  end

  def self.ransackable_associations(_auth_object = nil)
    reflections.keys
  end

  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end

  private

  def action_names_changed?
    defined?(@action_names) && !@action_names.nil?
  end

  def action_names_are_allowed
    return unless action_names_changed?

    invalid_actions = @action_names - AVAILABLE_ACTIONS
    return if invalid_actions.empty?

    errors.add(:action_names, "contain invalid values: #{invalid_actions.join(', ')}")
  end

  def save_action_names
    permission_group_abilities.where.not(action: @action_names).destroy_all

    @action_names.each do |action|
      permission_group_abilities.find_or_create_by!(action: action)
    end
  end

  def permission_group_item_blank?(attributes)
    item_type = attributes["item_type"] || attributes[:item_type]
    item_id = attributes["item_id"] || attributes[:item_id]

    item_type.blank? && item_id.blank?
  end
end
