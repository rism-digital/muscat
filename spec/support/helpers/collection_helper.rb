module CollectionHelper

  #This method iterates recursively over all elements of an object and returns them as array
  def flatten_all(object)
    raise(TypeError, "object is not a collection") unless object.class < Enumerable
    Enumerator.new do |yielder|
      object.each do |e|
        unless e.class < Enumerable
          yielder << e
        else
          flatten_all(e).each do |recursion|
            yielder << recursion
          end
        end
      end
    end
  end

  class ConfigHash 
    include Enumerable
    def initialize(c)
      @data = c
    end

    def getData
      @data
    end

    def contains?(str, obj=@data)
      if not obj.is_a? Enumerable
        return obj == str 
      else
        obj.each {|v|
          return true if contains?(str, v)
        }
      end
      return false
    end
  end

end


