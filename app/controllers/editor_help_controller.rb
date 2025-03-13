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
    # Use the legacy GD for all except English
    legacy = I18n.locale == :en ? false : true

    help_fname = EditorConfiguration.get_help_file(page, legacy)
    file_type = help_fname.end_with?(".md")

    begin
      file_data = IO.read("#{Rails.root}/public/#{help_fname}")
    rescue
      return "#{page} not found"
    end

    if file_type
      file_data = Redcarpet::Markdown.new(Redcarpet::Render::HTML).render(file_data).html_safe
      file_data += "<small style='color: gray;'>Muscat v11.4</small>".html_safe
    else
      file_data += "<small style='color: gray;'>Muscat v11.3</small>".html_safe
    end

    return file_data.html_safe
  end

end
