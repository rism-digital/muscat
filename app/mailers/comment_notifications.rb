class CommentNotifications < ApplicationMailer
	
  def new_comment(comment)
    
    all_comments = ActiveAdmin::Comment.where(resource_type: comment.resource_type, resource_id: comment.resource_id)
    @comment = comment
    # Try to get the owner of the resource
    @resource = Kernel.const_get(comment.resource_type).find(comment.resource_id)
    @commenter = User.find(comment.author_id)
    
    model_for_path = comment.resource_type.underscore.downcase
    link_function = "admin_#{model_for_path}_url"
    @resource_path = send(link_function, @resource)
    
    users = all_comments.map {|c| c.author_id}
    users << @resource.wf_owner
    users.uniq! # Users can be duplicated
    users -= [comment.author_id] # Don't send the comment to myself!

    addresses = users.each.map do |u|
      next if u == 1 # Don't sent to admin
      email = User.find(u).email
      next if !email
      email
    end.compact

    return if addresses.empty?

    mail(to: "noreply-muscat@rism.info",
        name: "Muscat Comments",
        bcc: addresses,
        subject: "New Comment on Muscat [#{comment.resource_type} #{comment.resource_id}]")
 
  end

end
