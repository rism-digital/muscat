class Statistic
  class Item
    attr_accessor :object, :sizes
    def initialize(object, sizes)
      @object=object
      @sizes=sizes
    end
  end

  attr_accessor :from_date, :to_date, :header, :items
  
  def initialize(array)
    @items = [] 
    array.each do |a|
      a.each do |k,v|
        @items << Item.new(k, v) 
    end
    end
    @header = @items.first.sizes.keys
    #ApplicationHelper.month_distance(from_date, to_date).each do |e|
     # @header << (Time.now + e.month).strftime("%Y-%m")
    #end
  end

  def with_attributes(options={})
    attributes = options[:attributes]
    insert_after = options[:insert_after] || 0
    existent = self.dup
    attributes.reverse.each { |att| existent.header.unshift(att) }
    existent.items.each do |item|
      line = ActiveSupport::OrderedHash.new
      item.sizes.keys.each_with_index do |key, index|
        attributes.each do |att|
          if index == insert_after
            line[att] = item.object.send(att)
          else
            line[key] = item.sizes[key]
          end
        end
      end
      item.sizes = line
    end
    return existent
  end

  def group_by(attribute)
    res = Hash.new()
    @items.each do |item|
      att = item.object.send(attribute)
      raise ArgumentError, "Unkown attribute" if !att
      sizes = res[att]
      if !sizes
        res[att] = item.sizes.values
      else
        item.sizes.values.each_with_index do |i, index|
          sizes[index] += i if i.is_a?(Integer) 
        end
      end
    end
    res
  end

 #Get an array of the Statistic.items
 #Options:
 #  :limit = set the size of the table
 #  :summarize = give the sum of sizes at the end of the row
 #  :columns = insert other values of the object
 #  :order = number of column to order the array
  def to_table(options={})
    attributes = options[:attributes]
    #limit = options[:limit] || -1
    #group = options[:group_by] || false
    #summarize = "TODO"
    #def to_table(attribute, options={:group_by => nil, :limit => -1, :summarize => false, :columns => [], :order => 1})
    #Build header
    #head = [attribute.to_s]
    #options[:columns].each {|c| head << c.to_s}
    #header.each {|h| head << h}
    #head << "SUM" if options[:summarize]
    
    #Build rows
    res = []
=begin
    if options[:group_by]
      e = with_attributes(:attributes => attributes)

      with_attributes(:attributes => attributes ).group_by(group).each do |e|
          line = []
          e.flatten.each {|field| line << field}
          if options[:summarize]
            line << e.flatten[1..-1].sum
          end
          res << line
        end
    else
=end
    result = with_attributes(:attributes=> attributes)
    res << result.header
      result.items.each do |item|
        res << item.sizes.values
        #name = item.object.send(attribute)
        #line << [("<a href='statistic?user=#{name}'>#{name}</a>").html_safe]
        #options[:columns].each do |c|
        #  column = item.object.send(c)
        #  if c == :workgroup && column
        #    line << ("<a href='statistic?workgroup=#{column}'>#{column}</a>").html_safe
        #  else
        #    line << (column.is_a?(Array) ? column.join(", ") : column)
        #  end
        #end
        #line << item.sizes.values
        #if options[:summarize]
        #  line << item.sizes.values.sum
        #end
        #res << line.flatten
      end
    #end
    #if options[:order]
    #  table = res.sort {|a,b| a[options[:order] -1 ] <=> b[options[:order] - 1]}
    #  table.unshift(head)
    #  return table
    #else
      #res.unshift(head)
      return res
    #end
  end

  def to_pie(attribute, options={:limit => -1})
    res = Hash.new(0)
    res2 = {}
    items.each do |item|
      res[item.object.send(attribute)] += item.sizes.values.sum
    end
    res.sort_by(&:last).reverse[0..options[:limit]].each do |e|
      res2[e[0]] = e[1]
    end
    return res2
  end

  def to_chart
    res = Hash.new(0)
    items.each do |item|
      header.each do |index|
        res[index] += item.sizes[index]
      end
    end
    return res
  end

end
