class MarcConfigCache
  def self.cache_all
    @configurations = Hash.new
    
		files = Dir.glob("#{Rails.root}/config/marc/tag_config*.yml").sort.each do |file|
      config = MarcConfig.new(file)
      @configurations[config.get_model] = config
    end
    
  end
  
  self.cache_all
  
  public
  
  def self.get_configuration(model)
  
    return nil if !@configurations.include? model
    @configurations[model]
  
  end
  
end