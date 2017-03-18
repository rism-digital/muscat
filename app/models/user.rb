class User < ActiveRecord::Base

  has_and_belongs_to_many :workgroups
  attr_accessible :email, :password, :preference_wf_stage, :password_confirmation if Rails::VERSION::MAJOR < 4
  has_many :sources, foreign_key: 'wf_owner'
# Connects this user object to Blacklights Bookmarks. 
  include Blacklight::User
  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, 
         :recoverable, :rememberable, :trackable, :validatable

  enum preference_wf_stage: [ :inprogress, :published, :deleted ]
  
  searchable :auto_index => false do
    integer :id
    text :name
    dynamic_integer :src_size, stored: true do
      result = {}
      ApplicationHelper.month_distance(Time.parse("2006-01-01"), Time.now).each do |index|
        date = Time.now.beginning_of_month + index.month
        result.merge!({ index  => sources.where(:created_at => (date .. date.end_of_month)).count})
      end
      result
    end
  end

  def sources_size_per_month(from_date, to_date)
    range = ApplicationHelper.month_distance(from_date, to_date)
    s = Sunspot.search(User) { with(:id, id) }
    res = []
    range.each do |index|
      res << s.hits.first.stored(:src_size, index.to_s)
    end
    return res
  end

  def can_edit?(source)
    if source.child_sources.count > 0
      libs=[]
      source.child_sources.each do |so| 
        so.institutions.each do |l|
          libs<<l
        end
      end
      (libs & (self.workgroups.map {|ins| ins.get_institutions}).flatten).any?
    else
      (source.institutions & (self.workgroups.map {|ins| ins.get_institutions}).flatten).any?
    end
  end

  def can_create_edition?(source)
    if (source.record_type == MarcSource::RECORD_TYPES[:edition] ||
      source.record_type == MarcSource::RECORD_TYPES[:edition_content] ||
      source.record_type == MarcSource::RECORD_TYPES[:libretto_edition_content] ||
      source.record_type == MarcSource::RECORD_TYPES[:theoretica_edition_content])
     if can? :create_edition?, source
       true
     else
       false
     end
   end
   true
  end

  def get_workgroups
    self.workgroups.map {|ins| ins.name}
  end
  
  def get_roles
    self.roles.map {|r| r.name}
  end

  def online?
      updated_at > 10.minutes.ago
  end
 
  def active?
    return false unless last_sign_in_at
    last_sign_in_at > (DateTime.now - 4.weeks) ? true : false
  end
end
