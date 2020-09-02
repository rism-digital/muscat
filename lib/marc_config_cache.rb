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

  def self.get_referring_associations_for(model)
    res = []

    @configurations.each do |conf_model, c|
      if c.get_all_foreign_classes.include?(model.to_s.pluralize.underscore)
        res << conf_model.pluralize.underscore
      end
    end
    return res
  end

end
