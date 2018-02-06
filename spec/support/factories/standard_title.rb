FactoryBot.define do
  factory :standard_title do
    id      3905618
    title   "Jesu meine Freude"
    title_d nil
    initialize_with { StandardTitle.find_or_create_by(id: id)  }
    created_at Time.now
  end
end
