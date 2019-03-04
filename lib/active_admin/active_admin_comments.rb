module ActiveAdmin
  module Comments
    module Views

      class Comments
        alias_method :"old_build_comment_form", :"build_comment_form"
        
        def build_comment_form
          old_build_comment_form
          span I18n.t('active_admin.comments.comments_help'), class: 'empty'
        end
        
      end
      
    end
  end
end