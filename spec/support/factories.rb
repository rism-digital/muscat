FactoryGirl.define do
  sequence :email do |n|
    "email#{n}@fory.com"
  end

  factory :user do
    email
    password "barfoobar"
    password_confirmation "barfoobar"
  end
end
