# We need to customize the comments for three things:
# 1) use a different parameter for pagination
# 2) append a "comments_help" text after the input box
# 3) Make URLs clickable in the comments
# Nr. 1 is the most tricky, as the inirialization function and the build comments function
# need to be overridden, so we can substitute the hard-coded :page parameter with a :comments_page parameter
# This is important as :page is persistent in the show page for the top navigation!
module ActiveAdmin
  module Comments
    module Views

      class Comments
        # Make a copy of the functions we will override
        alias_method :"old_build_comment_form", :"build_comment_form"
        alias_method :"old_build_comment", :"build_comment"
        
        def build(resource)
          @resource = resource
          ## This line originally uses :page, which conflicts with the saved :page paameter
          @comments = ActiveAdmin::Comment.find_for_resource_in_namespace(resource, active_admin_namespace.name).includes(:author).page(params[:comments_page])
          super(title, for: resource)
          build_comments
        end

        def build_comments
          if @comments.any?
            @comments.each(&method(:build_comment))
            div page_entries_info(@comments).html_safe, class: 'pagination_information'
          else
            build_empty_message
          end
          
          ## We need to tell kaminari to create pagination using the
          # :comments_page parameter instead of page
          text_node paginate @comments, param_name: :comments_page
          build_comment_form
        end
        
        # Override the function. We call the old one so the default stuff
        # gets generated, and then we append our small string of text
        def build_comment_form
          old_build_comment_form
          span I18n.t('active_admin.comments.comments_help'), class: 'empty'
        end
        
        # This makes the URLs clickabe in the comments
        # It uses Anchored to create the <a> tag, and substitutes the body text
        # Then the old rendering function is called
        def build_comment(comment)
          comment.body =  Anchored::Linker.auto_link(comment.body).html_safe
          old_build_comment(comment)
        end

      end
      
    end
  end
end