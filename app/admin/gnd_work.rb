ActiveAdmin.register_page "gnd_works" do
  menu :parent => "indexes_menu", priority: 24, label: proc{ I18n.t("active_admin.gnd_works") }, :if => proc{ current_user.has_role?(:admin) || current_user.has_role?(:gnd_work_editor)}
  
  controller do
    # These need to be manually added to the routes
    # The display_value label is included in the hash returned by the GND::Interface and is not a method of the model
    autocomplete :gnd_works, "person", :gnd => true, :display_value => :label, :extra_data => [:life_dates]
    autocomplete :gnd_works, "instrument", :gnd => true, :display_value => :label
    autocomplete :gnd_works, "keys", :display_value => :label, :getter_function => :get_autocomplete_keys_with_id

    autocomplete :gnd_works, "form", :gnd => true, :display_value => :label
    autocomplete :gnd_works, "title", :gnd => true, :display_value => :label

    def get_autocomplete_keys_with_id(token,  options = {})
      # Annoying, but here we are
      modes = {
        "A-Dur" => "1375005790",
        "As-Dur" => "1375005847",
        "B-Dur" => "1375005871",
        "C-Dur" => "1375005928",
        "Ces-Dur" => "137467365X",
        "Cis-Dur" => "1375005987",
        "D-Dur" => "1144915007",
        "Des-Dur" => "1375006037",
        "Dis-Dur" => "1375006096",
        "E-Dur" => "1375006134",
        "Eis-Dur" => "1375006177",
        "Es-Dur" => "7851492-7",
        "F-Dur" => "1375006193",
        "Fis-Dur" => "1375006223",
        "G-Dur" => "1375006258",
        "Ges-Dur" => "1375006304",
        "Gis-Dur" => "1375006398",
        "H-Dur" => "4642853-7",
        "a-Moll" => "110347894X",
        "ais-Moll" => "1374673668",
        "as-Moll" => "1375007378",
        "b-Moll" => "1375007394",
        "c-Moll" => "7851491-5",
        "cis-Moll" => "1375007416",
        "d-Moll" => "1375007432",
        "des-Moll" => "1375007459",
        "dis-Moll" => "1375007475",
        "e-Moll" => "1375007599",
        "es-Moll" => "1375007629",
        "f-Moll" => "1375007645",
        "fis-Moll" => "1375007653",
        "g-Moll" => "4412010-2",
        "ges-Moll" => "137500767X",
        "gis-Moll" => "1375007696",
        "h-Moll" => "1375007718",
        "Äolisch (Musik)" => "1045123625",
        "Dorisch (Musik)" => "4679314-8",
        "Hypoäolisch (Musik)" => "137500350X",
        "Hypodorisch (Musik)" => "7651336-1",
        "Hypoionisch (Musik)" => "1375003569",
        "Hypolokrisch (Musik)" => "137500378X",
        "Hypolydisch (Musik)" => "1375003917",
        "Hypomixolydisch (Musik)" => "1375004360",
        "Hypophrygisch (Musik)" => "1375004247",
        "Ionisch (Musik)" => "7852066-6",
        "Lokrisch (Musik)" => "1375003879",
        "Lydisch (Musik)" => "1057860603",
        "Mixolydisch (Musik)" => "4588914-4",
        "Phrygisch (Musik)" => "4588916-8",
        "a-Dorisch" => "1375005065",
        "A-Mixolydisch" => "1375005502",
        "a-Phrygisch" => "137500509X",
        "c-Dorisch" => "1375004905",
        "C-Mixolydisch" => "1375005545",
        "d-Dorisch" => "137500493X",
        "E-Mixolydisch" => "137500557X",
        "e-Phrygisch" => "1375005154",
        "f-Dorisch" => "1375004980",
        "F-Hypolydisch" => "1375005324",
        "F-Hypomixolydisch" => "1375005618",
        "F-Ionisch" => "1375005731",
        "F-Lydisch" => "1375005243",
        "g-Dorisch" => "1375005030",
        "G-Hypomixolydisch" => "1375005715",
        "G-Lydisch" => "137500526X",
        "G-Mixolydisch" => "1375005596",
        "g-Phrygisch" => "1375005197"
      }

      fake_struct = Struct.new(:id, :keys) do
        def [](attr)
          public_send(attr)
        end
      end

      return modes.filter_map { |mode, id| fake_struct.new("(DE-588)#{id}", mode) if mode.downcase.include?(token.downcase) }
    end

    MAX_SAVED_IDS_SIZE = 20

    def index

      if session.include?(:gnd_message)
        flash[:notice] = session[:gnd_message]
        session.delete(:gnd_message)
      end

      @saved_ids = nil
      @saved_ids = JSON.parse(cookies.permanent[:gnd_ids]) if cookies.permanent[:gnd_ids]

      render 'index', layout: "active_admin" 
    end

    def new
      @item = GndWork.new
      new_marc = MarcGndWork.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/gnd_work/default.marc")))
      new_marc.load_source false
      @item.marc = new_marc
      @editor_profile = EditorConfiguration.get_default_layout @item
      # Disable completely the editor validation
      @editor_validation = false #EditorValidation.get_default_validation(@item)
      render 'edit', layout: "active_admin" 
    end

    def edit
      @item = GndWork.new
      marc, xml = GND::Interface.retrieve(params[:id])
      if !marc
        redirect_to admin_gnd_works_path, :flash => { :error => "#{I18n.t(:gnd_not_found)} (GND id #{params[:id]})" }
        return
      end

      @item.marc = marc
      @editor_profile = EditorConfiguration.get_default_layout @item
      @editor_profile.add_fake_config(@item.marc)
      @editor_validation = false #EditorValidation.get_default_validation(@item)
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

      result, messages, author, title = GND::Interface.push(marc_hash, current_user)
      path = admin_gnd_works_path

      session[:gnd_message] = "GND Response: " + messages

      if result
        # Do we have the last saved ids cookie?
        ids = []
        if cookies.permanent[:gnd_ids]
          ids = JSON.parse(cookies.permanent[:gnd_ids]) rescue ids = []
        end

        # Use the array as a fixed-length FIFO
        ids.pop if ids.count > MAX_SAVED_IDS_SIZE
        # Make sure we have only the id
        new_id = result.gsub("ppn:","")
        # and no dups
        ids.reject! {|i| i["id"] == new_id}
        ids << {id: new_id, date: DateTime.now()} #, author: author, title: title}

        # Should we zip it?
        #zipped =Base64.encode64(ActiveSupport::Gzip.compress(JSON.generate(ids)))

        cookies.permanent[:gnd_ids] = JSON.generate(ids)
      end

      if result == nil
        render json: {gnd_message: messages, gnd_error: true }, status: 500
      else
        render json: { redirect: path }
      end
    end
  end

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
