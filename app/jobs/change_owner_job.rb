class ChangeOwnerJob < Muscat::ProgressTrackingJob
  
  def initialize(parent_obj_id, parent_obj_class, relation = :referring_works, user, requesting_user_id: nil)
    @parent_obj_id = parent_obj_id
    @parent_obj_class = parent_obj_class
    @relation = relation
    @user = user
    @requesting_user_id = requesting_user_id
  end
  
  def enqueue(job)
    return if !@parent_obj_id || !@parent_obj_class

    # We want a class here
    return if !@parent_obj_class.is_a? Class

    job.parent_id = @parent_obj_id
    job.parent_type = @parent_obj_class
    job.save!

  end

  def perform
    return if !@parent_obj_id
    return if !@user

    # Recheck the requesting admin's current access before executing.
    # The controller supplies this ID from current_user, never from params.
    if @parent_obj_class == Folder
      requester = User.find_by(id: @requesting_user_id)
      unless requester && !requester.disabled? && requester.has_role?(:admin)
        raise CanCan::AccessDenied, "Only administrators can change folder contents ownership"
      end
      raise ArgumentError, "Invalid folder relation" unless @relation == :folder_items
    end
    
    # Make sure the owner actually exists
    begin
      user = User.find(@user)
    rescue ActiveRecord::RecordNotFound
      update_stage("User not found")
      return
    end

    begin
      parent_obj = @parent_obj_class.send("find", @parent_obj_id)
    rescue ActiveRecord::RecordNotFound
      return # Just exit
    end

    update_stage("Reassign user")
    if parent_obj.is_a?(Folder)
      raise ArgumentError, "Unsupported folder type" unless parent_obj.owner_change_supported?

      # Use the folder's configured model; ignore dangling or mismatched joins.
      item_ids = parent_obj.folder_items.where(item_type: parent_obj.folder_type).select(:item_id)
      items = parent_obj.folder_model.where(id: item_ids)
    else
      items = parent_obj.send(@relation)
    end

    update_progress_max(items.count)
    
    count = 0
    items.each do |fi|
      fi = fi.item if fi.is_a?(FolderItem) 

      # Nothing to see here
      next if fi.wf_owner == user.id

      # Some folderable MARC models (for example Publications) do not support
      # 667. Only add ownership notes where the tag is configured.
      if fi.marc.config.has_tag?("667")
        found = false
        fi.marc["667"].each do |st|
          st["a"].each do |tt|
            found = true if tt&.content&.include?("Original cataloger:")
          end
        end

        if fi.wf_owner != 0 && fi.wf_owner != 1 && fi.user&.name && !found
          fi.marc.add_tag_with_subfields("667", a: "Original cataloger: #{fi.user.name}")
        end

        today = Date.today.strftime('%Y-%m-%d')
        fi.marc.add_tag_with_subfields("667", a: "Owner change #{today}. to: #{user.name}")
      end

      if  PaperTrail.request.enabled_for_model?(fi.class) 
        fi.paper_trail_event = "Change user to #{user.name}"
      end

      # Actually change the owner
      fi.wf_owner = user.id
      fi.save!
      
      update_stage_progress("Updating records #{count}/#{items.count}", step: 1)
      count += 1
    end
    
  end
  
  
  def destroy_failed_jobs?
    false
  end
  
  def max_attempts
    1
  end
  
  def queue_name
    'resave'
  end
end
