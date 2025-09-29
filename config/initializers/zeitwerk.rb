Rails.autoloaders.main.inflector.inflect(
    "gnd" => "GND")

Rails.autoloaders.each do |autoloader|
    autoloader.ignore(Rails.root.join('lib/generators/muscat/'))
    autoloader.ignore(Rails.root.join('lib/patches'))
end