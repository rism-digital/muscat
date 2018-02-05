FactoryBot.define do
  factory :standard_term do
    id 25160
    name "Operas"
  end

  factory :standard_term_variations, parent: :standard_term do 
    id 25218
    name "Variations"
  end
end
