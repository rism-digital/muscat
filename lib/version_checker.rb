module VersionChecker
  
  def self.save_version?(object)
    # first check the last version status
    return true if !object.versions || !object.versions.last || !object.versions.last.whodunnit
    # then check if we have information about who did it
    return true if !object.last_user_save
    # not the same user
    return true if object.versions.last.whodunnit != object.last_user_save
    # otherwise check at the time - wait at least one hour (3600 seconds)
    # we might want to make this configurable
    return true if (Time.now - object.versions.last.created_at.to_time) > 3600
    # else we don't want to save one
    return false
  end

end