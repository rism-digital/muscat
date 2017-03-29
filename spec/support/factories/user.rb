FactoryGirl.define do

  factory :user do
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
  
  factory :editor, :parent => :user do
    roles { [ FactoryGirl.create(:editor_role) ] }
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

end
