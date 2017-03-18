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
  
  def users_with_sources_size(from_date, to_date)
    res = {}
    users.each do |user|
      res[user] = user.sources_size_per_month(from_date, to_date)
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

  def self.most_active_users(from_date, to_date, statistic, limit=5)
    res1 = Hash.new(0)
    res2 = {}
    statistic.each do |k,v|
      v.each do |key, value|
        res1[key] += value.values.sum
      end
    end
    res1.sort_by(&:last).reverse[0..limit].each do |e|
      res2[e[0]] = e[1]
    end
    return res2

  end

  def sources_size_per_month(from_date, to_date)
    res = []
    users.each do |user|
      user.sources_size_per_month(from_date, to_date).each_with_index do |i, index|
        if res[index]
          res[index]  += i
        else
          res[index] = i
        end
      end
    end
    return res
  end

  def self.sources_by_range(from_date, to_date, workgroups)
    res = Hash.new(0)
    workgroups.each do |workgroup|
      res[workgroup] = workgroup.users_with_sources_size(from_date, to_date)
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
