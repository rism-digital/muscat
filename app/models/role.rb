class Role < ApplicationRecord
  has_and_belongs_to_many :users, :join_table => :users_roles
  belongs_to :resource, :polymorphic => true
  
  scopify

  def self.ransackable_attributes(_auth_object = nil)
    attribute_names
  end
end
