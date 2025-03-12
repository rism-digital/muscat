class EditorHelpController < ApplicationController
  before_action :authenticate_user!


  def render_page
    page = params[:page]   
    render html: render_markdown(page)
  end

  def render_page_in_box
    page = params[:page]
    @help_title = params[:title]
    @help_text = render_markdown(page)
   
    # do something with stuff_param
    render :template => 'editor/show_help'  
  end

  def current_user
    @current_user ||= authenticate
  end

  private

  def render_markdown(page) 
    help_fname = EditorConfiguration.get_markdown_help(page)

    begin
      markdown = IO.read("#{Rails.root}/public/#{help_fname}")
    rescue
      return "#{page} not found"
    end

    return Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(markdown).html_safe
  end

end
