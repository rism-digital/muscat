ActiveAdmin.register_page "Translation" do
  menu :parent => "admin_menu", :if => proc{ can? :manage, :all }

  page_action :edit, :method=>:post do
    if params['act']['Open']
      file=session['file']=params['open_file']['file']
      if params['open_file']['content'].size < 2 || file != params['open_file']['recent_file']
        session['content']=File.open(file, "r").read
      else
        session['content']=params['open_file']['content']
      end
      redirect_to translation_path
    end
    if params['act']['Save']
      text=params['open_file']['content']
      file=session['file']
      session['content']=text
      schema = Kwalify::Yaml.load_file('config/locales/schemas/lang.schema.yml')
      validator = Kwalify::Validator.new(schema)
      begin
        document = Kwalify::Yaml::load(text)
        errors=validator.validate(document)
        puts errors
        puts errors.size
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
        f.write(text)
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
