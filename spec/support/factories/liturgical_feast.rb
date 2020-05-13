FactoryBot.define do
  factory :liturgical_feast do
    id { 1 }
    name { "Christmas" }
    initialize_with { LiturgicalFeast.find_or_create_by(id: id)  } 
  end
end
