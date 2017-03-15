# Preview all emails at http://localhost:3000/rails/mailers/comment_notifications
class CommentNotificationsPreview < ActionMailer::Preview
	def new_comment
		co = ActiveAdmin::Comment.first
		ap co
		CommentNotifications.new_comment(co)
	end
end
