class Workgroup < ApplicationRecord

  has_and_belongs_to_many :users
  has_and_belongs_to_many :institutions
  after_save :change_institutions
  validates_presence_of :name 
  before_destroy :check_dependencies
  has_many :sources, :through => :users

  # to implement "Default workgroup for users"
  belongs_to :owner_user, class_name: "User", optional: true
  validates :owner_user_id, uniqueness: true, allow_nil: true
  # These are the normal non shared workgroups
  scope :shared, -> { where(personal_default: false) }

  searchable :auto_index => false do
    integer :id
    text :name
  end
   
  def get_institutions
    self.institutions.map {|lib| lib}
  end

  def check_dependencies
    if users.exists?
      errors.add(:base, "The workgroup could not be deleted because it is used")
      throw(:abort)
    end
  end

  def change_institutions
    self.institutions.delete_all
    pattern_list = self.libpatterns&.split(",")
    if libpatterns
      pattern_list.each do |pattern|
        self.institutions << Institution.where("siglum REGEXP ?", pattern.gsub("*", "").strip)
      end
    end
  end

  def show_libs
    libs = self.get_institutions.map(&:siglum)
    return libs.size > 4 ? "#{libs[0..4].join(', ')} [ ... #{libs.size - 5} more]" : libs.join(', ')
  end

  def self.ransackable_associations(_) = reflections.keys
  def self.ransackable_attributes(_) = attribute_names - %w[token]

end

