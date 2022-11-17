ActiveAdmin.register_page "gnd_works" do
  
  controller do
    def index
      render 'index', layout: "active_admin" 
    end

    def new
      @item = GndWork.new
      new_marc = MarcGndWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/gnd_work/default.marc")))
      new_marc.load_source false
      @item.marc = new_marc
      @editor_profile = EditorConfiguration.get_default_layout @item
      render 'edit', layout: "active_admin" 
    end

    def edit
      @item = GndWork.new
      new_marc = MarcGndWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/gnd_work/default.marc")))
      new_marc.load_source false
      @item.marc = new_marc
      @editor_profile = EditorConfiguration.get_default_layout @item
      render 'edit', layout: "active_admin" 
    end

    def search
      @results = GND::Interface.search(params[:q], "gnd_works")
      render 'search_results', layout: "active_admin", locals: { results: @results }
    end

    def marc_editor_validate
      marc_hash = JSON.parse params[:marc]
      current_user = User.find(params[:current_user])
      # hard coded here
      classname = "MarcGndWork"
      # Let it crash is the class is not fond
      dyna_marc_class = Kernel.const_get(classname)
      
      new_marc = dyna_marc_class.new()
      # Load marc, do not resolve externals
      new_marc.load_from_hash(marc_hash, user: current_user, dry_run: true)

      @item = GndWork.new
      @item.marc = new_marc
      
      @item.set_object_fields
      
      validator = MarcValidator.new(@item, current_user)
      validator.validate_tags
      validator.validate_links
      validator.validate_unknown_tags
      validator.validate_server_side

      if validator.has_errors
        render json: {status: validator.to_s}
      else
        render json: {status: I18n.t("validation.correct")}
      end
    end

    def marc_editor_save
      marc_hash = JSON.parse params[:marc]

      path = admin_gnd_works_path
      respond_to do |format|
        format.js { render :json => { :redirect => path }.to_json }
      end
    end
  end

  sidebar :toc, :class => "sidebar_tabs", :only => [:new, :edit] do
    render("sidebar_edit")
  end

  sidebar :filters, :class => "sidebar_tabs", :only => [:index, :search] do
    render("sidebar_index")
  end
  
end
