# Represents Muscat Users
class User < ApplicationRecord
  # Connects this user object to Blacklights Bookmarks.
  include Blacklight::User
  has_and_belongs_to_many :workgroups
  has_many :sources, foreign_key: 'wf_owner'

  rolify
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
	# remove :recoverable
  devise :database_authenticatable, 
         :rememberable, :trackable, :validatable

  enum notification_type: [:each, :daily, :weekly ]
  enum preference_wf_stage: [ :inprogress, :published, :deleted ]
  scope :ordered, -> {
    joins(:workgroups).order("workgroup.name")
          
  }
  
  # #515 postponed to 3.7
  #validate :secure_password

  searchable :auto_index => false do
    integer :id
    text :name
  end

  # Returns true when the user is allowed to edit a given source.
  # @param source [Source]
  # @return [Boolean]
  def can_edit?(source)
    if source.is_a? Holding
      self.workgroups.each do |workgroup|
        if workgroup.institutions.pluck(:siglum).include?(source.lib_siglum)
          return true
        end
      end
      return false
    end
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

  # Returns true when the user is allowed to create an edition for the given source.
  # @param (see #can_edit?)
  def can_create_edition?(source)
    if (source.record_type == MarcSource::RECORD_TYPES[:edition] ||
      source.record_type == MarcSource::RECORD_TYPES[:edition_content] ||
      source.record_type == MarcSource::RECORD_TYPES[:libretto_edition] ||
      source.record_type == MarcSource::RECORD_TYPES[:theoretica_edition])
     if can? :create_edition?, source
       true
     else
       false
     end
   end
   true
  end

  # Returns true when the user is allowed to edit an edition.
  # @param (see #can_edit?)
  def can_edit_edition?(source)
    source.holdings.each do |holding|
      return true if self.can_edit?(holding)
    end
    if source.source_id
      ## These two statuses are pretty major, send a mail
      if source.id == source.source_id
        puts "Source #{source.id} has identical source_id (#{source.source_id})"
        AdminNotifications.notify("Source #{source.id} has identical source_id (#{source.source_id})", @item).deliver_now
      elsif source.parent_source.source_id == source.id
        puts "Source #{source.id} has a parent (#{source.parent_source.id}) that has this source as parent!"
        AdminNotifications.notify("Source #{source.id} has a parent (#{source.parent_source.id}) that has has this source as parent!", @item).deliver_now
      else
          return true if self.can_edit_edition?(source.parent_source)
      end
    end
    return false
  end

  # Checks if a folder content all items are the user domain
  # @return [Boolean]
  def can_publish?(folder)
    return false unless folder.folder_type == 'Source'
    folder_sigla = folder.content.pluck(:lib_siglum).uniq
    own_sigla = self.workgroups.map{|w| w.institutions.pluck(:siglum)}.flatten
    return false unless (folder_sigla - own_sigla).empty?
    return true
  end

  # Gets the Names of the Workgroups the User is in.
  # @return [Array<String>]
  def get_workgroups
    self.workgroups.map {|ins| ins.name}
  end
  
  # Gets the Names of the Workgroups the User is in.
  # @return [String]
  def workgroup
    get_workgroups.join(", ")
  end

  # Gets the Names of the Roles of the User.
  # @return [Array<String>]
  def get_roles
    self.roles.map {|r| r.name}
  end

  # Returns true when user has been seen the last ten minutes.
  # @return [Boolean]
  def online?
      updated_at > 10.minutes.ago
  end
 
  # Returns true when user has been seen the last two weeks.
  # @return [Boolean]
  def active?
    return false unless last_sign_in_at
    last_sign_in_at > (DateTime.now - 12.weeks) ? true : false
  end

  # Tests whether User has Restrictions on the given Model.
  # @param model [String]
  # @return [Boolean]
  def restricted?(model)
    roles.select {|r| r.name =~ /restricted/}.each do |role|
      restricted_model = role.name.split("_")[0]
      if model != restricted_model
        next
      else
        return true
      end
    end
    return false
  end

  # Returns false when User does not receive Notifications
  # and the list of Elements to be noted about otherwise.
  # @return [false, Hash]
  # @todo test the Hash
  def get_notifications
    return false if !notifications || notifications.empty?
    elements = {}
    notifications.each_line do |line|
      parts = line.strip.split(":")
      next if parts.count < 2
      next if parts[0].empty? # :xxx case
      elements[parts[0]] = [] if !elements.include?(parts[0])
      elements[parts[0]] << parts[1]
    end
    return elements
  end

  # Returns a list of Users sorted by lastname with admin at first place, utf-8 chars included.
  # @return [Array<String>]
  def self.sort_all_by_last_name
    res = {}
    User.all.each do |u|
      res[u.id] = [I18n.transliterate(u.name.sub("Admin", "00admin").split(" ").last).downcase, u]
    end
    return res.sort_by{|_key, value| value.first}.map {|e| e[1][1] }
  end
  
=begin #515 postponed to 3.7
  def secure_password
    return true if !password
    if (password.length < 8)
      errors.add :password, "the password must to be at least 8 characters long"
      return false
    end
    if (password =~ /[a-z]/).blank?
      errors.add :password, "the password must to contain at least one lower case letter"
      return false
    end
    if (password =~ /[A-Z]/).blank?
      errors.add :password, "the password must to contain at least one upper case letter"
      return false
    end
    if (password =~ /[0-9]/).blank?
      errors.add :password, "the password must to contain at least one number"
      return false
    end
    return true
	end
=end
end
