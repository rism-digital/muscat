


def convert_hash_to_ordered_hash_and_sort(object, deep = false)
# from http://seb.box.re/2010/1/15/deep-hash-ordering-with-ruby-1-8/
  if object.is_a?(Hash)
    # Hash is ordered in Ruby 1.9! 
    res =  Hash.new do |map|
      object.each {|k, v| map[k] = deep ? convert_hash_to_ordered_hash_and_sort(v, deep) : v }
    end
    return res.class[res.sort {|a, b| a[0].to_s <=> b[0].to_s } ]
  elsif deep && object.is_a?(Array)
    array = Array.new
    object.each_with_index {|v, i| array[i] = convert_hash_to_ordered_hash_and_sort(v, deep) }
    return array
  else
    return object
  end
end

h = YAML::load(File.read("/Users/xhero/devel/translations/locales/en.yml"))

ap convert_hash_to_ordered_hash_and_sort(h)