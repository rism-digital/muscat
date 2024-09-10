  require 'net/http'
require 'uri'

def test_link(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)

  # Controlla se la risposta è stata un successo (codice di stato 200)
  if !response.is_a?(Net::HTTPSuccess)
    puts
    puts url
  end
end

image_map = YAML::load(File.read('housekeeping/inventories_migration/ms2image.yml'), permitted_classes: [ActiveSupport::HashWithIndifferentAccess, Time, Date, ActiveSupport::TimeWithZone, ActiveSupport::TimeZone])

spinner = TTY::Spinner.new("[:spinner] :title", format: :shark)
image_map.each do |images|
    images[1].each do |image|
        next if image == "[spacer]"

        spinner.update(title: "#{image}...")
        spinner.auto_spin

        url = "https://iiif.rism.digital/image/in/#{image}/full/full/0/default.jpg"
        test_link(url)
    end
end