#Wrapper for accessing YAML I18n files
class Translation
  
  attr_accessor :lang, :labels, :locales
  def initialize(lang)
    @lang = lang
    @labels = [] 
    @locales = []
  end

  # returning list of ["de.alert", "alarm"] key-value pairs
  def locales_from_yaml
    res = {}
    yaml = YAML.load_file("config/locales/#{lang}.yml")
    _flat_hash(yaml).each do |k,v|
      res[k[1..-1].join(".")] = v
    end
    @locales = res.sort
    return self
  end

  # writing back key-value pairs as yaml-hash
  def locales_to_yaml
    hash = locales.to_h.each_with_object({}) do |(key,value), all|
      key_parts = [lang] + key.split('.').map!(&:to_s)
      leaf = key_parts[0...-1].inject(all) { |h, k| h[k] ||= {}  }
      if value.include?("___ARR___")
        leaf[key_parts.last] = value.split("___ARR___")
      else
        leaf[key_parts.last] = value
      end
    end
    File.write("tmp/#{lang}.yml", hash.to_yaml)
    hash.to_yaml
  end

  # hashes of labels from different models (eg. PersonLabels, WorkLabels etc.) as key-value list
  def labels_from_yaml
    arr = []
    Dir["config/editor_profiles/default/configurations/*Labels.yml"].each do |file|
      file_hash = {}
      filename = File.basename(file, ".yml")
      yaml = YAML.load_file(file)
      _flat_hash(yaml).each do |k,v|
        file_hash[filename + "." + k[0..-2].join(".")] = v if k.last == lang
      end
      arr << file_hash.sort
    end
    arr.each do |e|
      e.each do |k|
        labels << k
      end
    end
    return self
  end

  # returning key-value pairs as yaml hash
  def labels_to_yaml(model)
    x = labels.select{|e| e[0].starts_with?(model)}
    y = x.map{|e| [e[0].gsub("#{model}.", "") + ".#{lang}", e[1]]}
    hash = y.to_h.each_with_object({}) do |(key,value), all|
      key_parts = key.split('.').map!(&:to_s)# unless key.starts_with?(model)
      leaf = key_parts[0...-1].inject(all) { |h, k| h[k] ||= {}  }
      if value.include?("___ARR___")
        leaf[key_parts.last] = value.split("___ARR___")
      else
        leaf[key_parts.last] = value
      end
    end
    return hash
  end

  # merging label files from different languages
  def self.merge_labels(*translations, model)
    res = translations.first.labels_to_yaml(model)
    translations[1..-1].each do |t|
      hash = t.labels_to_yaml(model)
      res.deep_merge!(hash)
    end
    File.write("tmp/#{model}.yml", res.to_yaml)
    return res
  end

  # helper method to flatten yaml hash
  def _flat_hash(h,f=[],g={})
    if h.is_a? String
      return g.update({ f=>h  })
    elsif h.is_a? Array
      return g.update({ f=>h.join("___ARR___")  })
    end
    h.each { |k,r| _flat_hash(r,f+[k],g)  } rescue nil
    g
  end

end
