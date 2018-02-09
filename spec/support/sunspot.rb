models = [ Source, Person, Catalogue, Institution ]

RSpec.configure do |config|
  config.before(:each, solr: true) do
    models.each do |model|
      unless Sunspot.search(model).hits.empty?
        model.remove_all_from_index
      end
    end
    Sunspot.commit
    puts "Cleaned Sunspot::Solr".blue
  end
end
