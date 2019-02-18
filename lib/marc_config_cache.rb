# Loads all the configurations from the files in config/marc/tag_config*.yml

class MarcConfigCache
  def self.cache_all
    @configurations = Hash.new
		Dir.glob("#{Rails.root}/config/marc/tag_config*.yml").sort.each do |file|
      config = MarcConfig.new(file)
      @configurations[config.get_model] = config
    end
  end
  
  # @todo Is that nice to have a Method call inside of the Class-Definition?
  self.cache_all
  
  public
  
  # Gets the Marc Configuration for a given Model
  # @param model [String] Model Name
  # @return [MarcConfig]
  def self.get_configuration(model)
    return nil if !@configurations.include? model
    @configurations[model]
  end
  
  # Adds Overlay
  # (see #MarcConfig.add_overlay)
  def self.add_overlay(model, overlay_path)
    model = model.downcase
    filename = ""
    return nil if !@configurations.include? model
		Dir.glob("#{Rails.root}/config/marc/tag_config*.yml").sort.each do |file|
      config = MarcConfig.new(file)
      filename = file if config.get_model == model
    end
    @configurations[model].add_overlay(filename, overlay_path)
  end
end
