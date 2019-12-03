#Wrapper for accessing YAML I18n files
class Translation
  
  attr_accessor :lang, :labels, :locales, :languages
  def initialize(lang)
    @lang = lang
    @labels = []
    labels_from_yaml
    @locales = []
    locales_from_yaml
  end

  # returning list of ["de.alert", "alarm"] key-value pairs
  def locales_from_yaml
    res = []
    yaml = YAML.load_file("config/locales/#{lang}.yml")
    _flat_hash(yaml).each do |k,v|
      res << {"code" => k[1..-1].join("."), lang => v}
    end
    @locales = res
    return self
  end

  # writing back key-value pairs as yaml-hash
  def locales_to_yaml
    hash = locales.each_with_object({}) do |(key), all|
      key_parts = [lang] + key["code"].split('.').map!(&:to_s)
      leaf = key_parts[0...-1].inject(all) { |h, k| h[k] ||= {}  }
      if key[lang].include?("___ARR___")
        leaf[key_parts.last] = key[lang].split("___ARR___")
      else
        leaf[key_parts.last] = key[lang]
      end
    end
    File.write("tmp/#{lang}.yml", hash.to_yaml)
    hash.to_yaml
  end

  # hashes of labels from different models (eg. PersonLabels, WorkLabels etc.) as key-value list
  def labels_from_yaml
    arr = []
    Dir["config/editor_profiles/default/configurations/*Labels.yml"].each do |file|
      filename = File.basename(file, ".yml")
      yaml = YAML.load_file(file)
      _flat_hash(yaml).each do |k,v|
        arr << {"code" => filename + "." + k[0..-2].join("."), lang => v} if k.last == lang
      end
    end
    @labels = arr
    return self
  end

  # returning key-value pairs as yaml hash
  def labels_to_yaml(model)
    x = labels.select{|e| e["code"].starts_with?(model)}
    y = x.map{|e| [e["code"].gsub("#{model}.", "") + ".#{lang}", e[lang]]}
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

  def update(key, value)
    model = nil
    locales.each do |e|
      if e["code"] == key
        e[lang] = value
        locales_to_yaml
        return self
      end
    end
    labels.each do |e|
      if e["code"] == key
        e[lang] = value
        model = key.split(".").first
        #labels_to_yaml(model)
        Translation.merge_labels(Translation.new("en"), self, model)

        return self
      end
    end
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

  def self.combine(*translations)
    t1 = translations.first.locales
    codes1 = t1.map{|e| e["code"]}
    translations[1..-1].each do |t|
      t.locales.each do |e|
        t1[codes1.index(e["code"])].merge!(e) rescue next
      end
    end
    t2 = translations.first.labels
    codes1 = t2.map{|e| e["code"]}
    translations[1..-1].each do |t|
      t.labels.each do |e|
        t2[codes1.index(e["code"])].merge!(e) rescue next
      end
    end
    return t1 + t2
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

  def languages
    %w( en de fr it )
  end

  def models
    %w( Source Holding Person Institution Catalogue Work )
  end

end
