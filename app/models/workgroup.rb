class Workgroup < ActiveRecord::Base

    has_and_belongs_to_many :users
    has_and_belongs_to_many :libraries
    after_save :change_libraries
    validates_presence_of :name 
    before_destroy :check_dependencies

   searchable :auto_index => false do
    integer :id
    text :name
  end
 
  def get_libraries
    self.libraries.map {|lib| lib}
  end

  def check_dependencies
    if self.users.size > 0
      errors.add :base, "The workgroup could not be deleted because it is used"
      return false
    end
  end

  def change_libraries
    self.libraries.delete_all
    pattern_list=self.libpatterns.split(",")
    if libpatterns
      pattern_list.each do |siglum|
        self.libraries << Library.where("siglum like ?", "%#{siglum.gsub("*", "").strip}%")
      end
    end
  end
 
end
