# This class is used to read the editor profile configurations
# from yaml files. It is needed in the first migration to read all the conf
# Used in 199_sample_editor_profiles.rb 

class Settings < Hash
  def initialize(source = nil)
    if source.is_a? Hash
      update source
    elsif !source.nil?
      update YAML::load(source)
    end
  end
  
  def dive(struct, from)
    
    struct.each do |k, v|
      if v.is_a?(Hash) and from[k]
        dive(v, from[k])
      elsif v.is_a?(Array) and from[k]
        from[k] = (from[k] + v).uniq
      else
        from[k] = v
      end
    end
  end
  
  def squeeze(other)
    other.each do |k, v|
      if v.is_a?(Hash) and self[k]
        dive(v, self[k])
      else
        update({ k => v })
      end
    end
  end
  
  def to_yaml_sorted( opts = {} )
    YAML::quick_emit( object_id, opts ) do |out|
      out.map( taguri, to_yaml_style ) do |map|
        sort.each do |k, v|
          map.add( k, v.force_encoding("utf-8") )
        end
      end
    end
  end

  alias settings to_yaml_sorted
  alias struct to_yaml_sorted
  alias to_s to_yaml_sorted
  
end
