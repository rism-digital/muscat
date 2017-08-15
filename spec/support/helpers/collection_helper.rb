module CollectionHelper

  #This method iterates recursively over all elements of an object and returns them as array
  def flatten_all_to_array(object, result = [])
    raise(TypeError, "object is not a collection") unless object.class < Enumerable
    object.each do |e|
      unless e.class < Enumerable
        result << e
      else
        flatten_all(e, result)
      end
     end
    return result
  end

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
    end.lazy
  end

end
