FactoryGirl.define do

  factory :user do
    name "Fred"
    email "admin@example.com"
    password "password"
    password_confirmation "password"
  end

  factory :admin, :parent => :user do
    roles { [ FactoryGirl.create(:admin_role) ] }
  end

  factory :cataloger, :parent => :user do
    roles { [ FactoryGirl.create(:cataloger_role) ] }
  end
 
  factory :guest, :parent => :user do
    roles { [ FactoryGirl.create(:guest_role) ] }
  end
  
  factory :editor, :parent => :user do
    roles { [ FactoryGirl.create(:editor_role) ] }
  end

  factory :person_editor, :parent => :user do
    roles { [ FactoryGirl.create(:editor_role),  FactoryGirl.create(:person_editor_role),  ] }
  end

  factory :person_restricted, :parent => :user do
    roles { [ FactoryGirl.create(:cataloger_role),  
              FactoryGirl.create(:person_restricted_role),  ] }
  end


  factory :role do
    name        { "Role_#{rand(9999)}"  }
  end

  factory :admin_role, :parent => :role do
    name "admin"
  end

  factory :cataloger_role, :parent => :role do
    name "cataloger"
  end

  factory :editor_role, :parent => :role do
    name "editor"
  end

  factory :guest_role, :parent => :role do
    name "guest"
  end

  factory :person_editor_role, :parent => :role do
    name "person_editor"
  end

  factory :person_restricted_role, :parent => :role do
    name "person_restricted"
  end


end
