FactoryBot.define do
  factory :standard_term do
    id               25240
    term             "Motets"
    alternate_terms  "Motetten"
    initialize_with { StandardTerm.find_or_create_by(id: id)  } 
  end
end
