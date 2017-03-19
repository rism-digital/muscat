class Statistic
  class Item
    attr_accessor :object, :sizes
    def initialize(object, sizes)
      @object=object
      @sizes=sizes
    end
  end

  attr_accessor :from_date, :to_date, :header, :items
  
  def initialize(from_date, to_date, users)
    @from_date=from_date
    @to_date=to_date
    @items = [] 
    users.each do |user|
      @items << Item.new(user, user.sources_size_per_month(from_date, to_date))
    end
    @header = []
    ApplicationHelper.month_distance(from_date, to_date).each do |e|
      @header << (Time.now + e.month).strftime("%Y-%m")
    end
  end

  def group_by(attribute)
    res = Hash.new()
    @items.each do |item|
      if attribute == :workgroups
        att = item.object.workgroups.first ? item.object.workgroups.first : "[without workgroup]" 
      elsif attribute == :all
        att = :all
      else
        att = item.object[attribute]
      end
      raise ArgumentError, "Unkown attribute" if !att
      sizes = res[att]
      if !sizes
        res[att] = item.sizes
      else
        item.sizes.each_with_index do |i, index|
          sizes[index] += i 
        end
      end
    end
    res
  end

  def to_table(attribute, limit=-1)
    res = []
    items = group_by(attribute)
    items.each do |i|
      res << i.flatten
    end
    return res
  end

  def to_csv

  end

  def to_pie(attribute, limit=-1)
    res = Hash.new(0)
    res2 = {}
    group_by(attribute).each do |k,v|
      name = k rescue "without workgroup"
      res[name] = v.sum if name
    end
    res.sort_by(&:last).reverse[0..limit].each do |e|
      res2[e[0]] = e[1]
    end
    return res2
  end

end
