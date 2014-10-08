class Workgroup < ActiveRecord::Base

    has_and_belongs_to_many :users
    has_and_belongs_to_many :libraries
  
    validates_presence_of :name 

   searchable :auto_index => false do
    integer :id
    string :name_order do
      name
    end
    text :name
  
    text :alternates  
    text :notes
    
    integer :src_count_order do 
      src_count
    end
  end
 
  def get_libraries
    self.libraries.map {|lib| lib}
  end

  def add_library(siglum)
    self.libraries << Library.where("siglum like ?", "%#{siglum}%")
  end

  def remove_library(siglum)
    self.libraries.delete(Library.where("siglum like ?", "%#{siglum}%"))
  end
 
 
end
