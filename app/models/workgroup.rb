class Workgroup < ActiveRecord::Base

    has_and_belongs_to_many :users
    has_and_belongs_to_many :institutions
    after_save :change_institutions
    validates_presence_of :name 
    before_destroy :check_dependencies
    has_many :sources, :through => :users

    searchable :auto_index => false do
      integer :id
      text :name
    end
  
  def each_with_sources_size(from_date, to_date, array)
    res = {}
    array.each do |item|
      res[item] = item.sources_size_per_month(from_date, to_date)
    end
    return res
  end

  def self.most_active_workgroups(from_date, to_date, limit=5)
    res1 = {}
    res2 = {}
    hash = self.workgroups_with_sources_size(from_date, to_date)
    hash.each do |k,v|
      res1[k] = v.values.sum
    end
    res1.sort_by(&:last).reverse[0..limit].each do |e|
      res2[e[0]] = e[1]
    end
    return res2
  end

  def most_active_users(from_date, to_date, limit=5)
    res1 = {}
    res2 = {}
    hash = each_with_sources_size(from_date, to_date, users)
    hash.each do |k,v|
      res1[k] = v.values.sum
    end
    res1.sort_by(&:last).reverse[0..limit].each do |e|
      res2[e[0]] = e[1]
    end
    return res2

  end

  def sources_size_per_month(from_date, to_date)
    res = Hash.new(0)
    each_with_sources_size(from_date, to_date, users).each do |k,v|
      v.each do |key,value|
        res[key] += value
      end
    end
    return res
  end

  def self.all_sources_by_range(from_date, to_date)
    res = Hash.new(0)
    Workgroup.all.each do |workgroup|
      workgroup.sources_size_per_month(from_date, to_date).each do |k,v|
        res[k] += v
      end
    end
    return res
  end
  
  def get_institutions
    self.institutions.map {|lib| lib}
  end

  def check_dependencies
    if self.users.size > 0
      errors.add :base, "The workgroup could not be deleted because it is used"
      return false
    end
  end

  def change_institutions
    self.institutions.delete_all
    pattern_list=self.libpatterns.split(",")
    if libpatterns
      pattern_list.each do |pattern|
        self.institutions << Institution.where("siglum REGEXP ?", pattern.gsub("*", "").strip)
      end
    end
  end

  def show_libs
    libs = self.get_institutions.map(&:siglum)
    return libs.size > 4 ? "#{libs[0..4].join(', ')} [ ... #{libs.size - 5} more]" : libs.join(', ')
  end
end
