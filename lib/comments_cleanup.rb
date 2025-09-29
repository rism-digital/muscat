module CommentsCleanup
    def cleanup_comments
        ActiveAdmin::Comment.where(resource: self).each do |comment|
            comment.destroy
        end
    end
end 