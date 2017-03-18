class Statistic
  class Item
    attr_accessor :object, :sizes
    def initialize(object, sizes)
      @object=object
      @sizes=sizes
    end
  end

  attr_accessor :from_date, :to_date, :header, :items
  
  def initialize(from_date, to_date)
    @from_date=from_date
    @to_date=to_date
    @items = [] 
    @header = []
    ApplicationHelper.month_distance(from_date, to_date).each do |e|
      @header << (Time.now + e.month).strftime("%Y-%m")
    end
  end

  def add(users)
    users.each do |user|
      @items << Item.new(user, user.sources_size_per_month(from_date, to_date))
    end
  end


  def users_by_workgroup

  end

  def by_workgroup

  end

  


end
