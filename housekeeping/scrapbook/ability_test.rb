#WORKFLOW
#
#Prerequisite
#FIXME: Actual there are no relations from source to library

#sources_all = Source.where("length(lib_siglum) > 1")
#sources_all.each do | source | source.libraries << Library.where(:siglum => source.lib_siglum).take end

#Step 1: Create user
#
user = User.find_by :name => "stephan"
#
#Step 2: Create workgroup
#Institution.create(:name => "Workgroup India")
workgroup = Institution.find_by :name => "Workgroup India"

#Step 3: Adding libraries to workgroup
#workgroup.libraries << Library.find_by :siglum => 'D-Mbs'
#workgroup.libraries << Library.find_by :siglum => 'GB-Bu'
#workgroup.add_library('GB-Lbl')

#Step 4: Applying workgroup to user
#user.institutions << workgroup

#Step 5: Test and enjoy :-)
source = Source.find_by :lib_siglum => 'GB-Lbl'

p user.can_edit? source
#p (source.libraries & (user.institutions.collect {|ins| ins.libraries.collect {|lib| lib}}).flatten).any?

#DEPRECATED
=begin
user_lib=[]
user.institutions.each do |inst|
  inst.libraries.each do |lib|
    user_lib << lib
  end
end
p (source.libraries & user_lib).any?
=end

