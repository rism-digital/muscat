models = [ Source, Person, Catalogue, Institution ]

RSpec.configure do |config|
  config.after(:each) do
    models.each do |model|
      unless Sunspot.search(model).hits.empty?
        Sunspot.remove_all!(model)
      end
    end
  end
end
