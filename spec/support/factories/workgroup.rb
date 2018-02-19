FactoryBot.define do
  factory :workgroup do
    name "Germany"
    libpatterns "^D-*"
    institutions { [association(:institution)] }
  end
end
