ActiveAdmin.register_page "doc" do
  DOCUMENTED_MODELS = {
    "Source" => Source,
    "Person" => Person,
    "Institution" => Institution,
    "Publication" => Publication,
    "Work" => Work
  }.freeze

  menu parent: "admin_menu",
       label: proc { I18n.t(:menu_marc_documentation) }

  controller do
    def index
      @model_class =
        DOCUMENTED_MODELS.fetch(params[:model].presence || "Source", Source)

      @model_name = @model_class.model_name.element
      @model = @model_class.new
    end
  end

  content title: proc {
    "#{I18n.t(:menu_marc_documentation)} - #{@model_class.model_name.human}"
  } do
    render partial: "fields"
  end

  sidebar :models, class: "sidebar_tabs", only: :index do
    render "doc_sidebar"
  end
end