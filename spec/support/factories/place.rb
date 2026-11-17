FactoryBot.define do
  factory :place do
    id { 3900054 }
    name { "Berlin" }
    initialize_with { Place.find_or_initialize_by(id: id) }
  end
end
