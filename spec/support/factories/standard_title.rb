FactoryBot.define do
  factory :standard_title do
    id 3942594
    title "Kunst der Fuge"
  end
  factory :standard_title_variations, parent: :standard_title do
    id 3900139
    title "Variations"
  end
end
