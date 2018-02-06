FactoryBot.define do
  factory :place do
    id 3900054
    name "Berlin"
    initialize_with { Place.find_or_create_by(id: id)  } 
  end
end
