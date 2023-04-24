ActiveAdmin.register_page "gnd_works" do
  controller do
    # The display_value label is included in the hash returned by the GND::Interface and is not a method of the model
    autocomplete :gnd_works, "person", :gnd => true, :display_value => :label, :extra_data => [:life_dates]
    autocomplete :gnd_works, "instrument", :gnd => true, :display_value => :label


    def index

      if session.include?(:gnd_message)
        flash[:notice] = session[:gnd_message]
        session.delete(:gnd_message)
      end

      render 'index', layout: "active_admin" 
    end

    def new
      @item = GndWork.new
      new_marc = MarcGndWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/gnd_work/default.marc")))
      new_marc.load_source false
      @item.marc = new_marc
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_validation = EditorValidation.get_default_validation(@item)
      render 'edit', layout: "active_admin" 
    end

    def edit
      @item = GndWork.new
      marc = GND::Interface.retrieve(params[:id])
      @item.marc = marc
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_profile.add_fake_config(@item.marc)
      @editor_validation = EditorValidation.get_default_validation(@item)
      render 'edit', layout: "active_admin" 
    end

    def search
      begin
        params.require(:q).permit(:composer, :title)

        @composer = params[:q][:composer]
        @title = params[:q][:title]

        @results = GND::Interface.search(params[:q], 30)
      rescue ActionController::ParameterMissing
        @results = nil
      end
      render 'search_results', layout: "active_admin", locals: { results: @results }
    end

    #########################
    ## Marc editor actions ##
    #########################

    # For normal use of the Marc editor, these action are implemented in the MarcControllerActions module
    # Because we have no underlying model here the action needed are implemented separately

    def marc_editor_validate
      marc_hash = JSON.parse params[:marc]
      current_user = User.find(params[:current_user])
      
      new_marc = MarcGndWork.new()
      # Load marc, do not resolve externals
      new_marc.load_from_hash(marc_hash, user: current_user, dry_run: true)

      @item = GndWork.new
      @item.marc = new_marc
      
      @item.set_object_fields
      
      validator = MarcValidator.new(@item, current_user)
      validator.validate_tags

      if validator.has_errors
        render json: {status: validator.to_s}
      else
        render json: {status: I18n.t("validation.correct")}
      end
    end

    def marc_editor_save
      marc_hash = JSON.parse params[:marc]

      result, messages = GND::Interface.push(marc_hash)
      path = admin_gnd_works_path

      session[:gnd_message] = "GND Response: " + messages

      if result == nil
        render json: {gnd_message: messages, gnd_error: true }, status: 500
      else
        render json: { redirect: path }
      end
    end
  end

  menu priority: 24, label: proc{ I18n.t("active_admin.gnd_works") }

  ##############
  ## Sidebars ##
  ##############

  sidebar :toc, :class => "sidebar_tabs", :only => [:new, :edit] do
    render("sidebar_edit")
  end

  sidebar :filters, :class => "sidebar_tabs", :only => [:index, :search] do
    render("sidebar_index")
  end
  
end
