ActiveAdmin.register_page "Translation" do
  menu :parent => "admin_menu", :if => proc{ can? :manage, :all }

  page_action :edit, :method=> :post do
    if params['act']['Open']
      session['file']=file=params['open_file']['file']
      FileUtils.cp(file, 'tmp/trans.yml')
      content=File.open(file, "r").read
      redirect_to translation_path
    end
    if params['act']['Save']
      session['file']=file=params['open_file']['file']
      content=params['open_file']['content']
      trans=File.open("tmp/trans.yml", "w")
      trans.write(content)
      schema = Kwalify::Yaml.load_file('config/locales/schemas/lang.schema.yml')
      validator = Kwalify::Validator.new(schema)
      begin
        document = Kwalify::Yaml::load(content)
        errors=validator.validate(document)
        ## show errors
        if errors && !errors.empty?
          for e in errors
            if e.message.include?("required")
              flash[:error] = "SYNTAX ERROR: "+e.message+" Unable to save translation file!"
              redirect_to translation_path
              return 1
            end
            puts "[#{e.path}] #{e.message}"
          end
        end
        f=File.open(file, "w")
        f.write(content)
        redirect_to translation_path, notice: 'Translation file saved!'
    rescue Kwalify::SyntaxError => e
        flash[:error] = "SYNTAX ERROR: "+e.message+" Unable to save translation file!"
        redirect_to translation_path
      end
    end
  end

  content do
    panel "Translation" do 
      render 'index'
    end
  end
end
