require 'yaml'

class IndexConfig
  def self.cache_all
    @configurations = Hash.new

    files = Dir.glob("#{Rails.root}/config/marc_index/index_config*.yml").sort.each do |file|
      config = YAML::load(File.read(file))
      @configurations[config["config"][:model]] = config
    end

  end

  self.cache_all

  public

  def self.get_configuration(model)
    return nil if !@configurations.include? model
    @configurations[model]
  end

  def self.get_fields(model)
    return nil if !@configurations.include? model
    @configurations[model]["fields"]
  end

end
