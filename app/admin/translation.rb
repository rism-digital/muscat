ActiveAdmin.register_page "Translations" do
  menu :parent => "admin_menu", :if => proc{ can? :manage, :all }

  page_action :trans, :method=>:post do
    text=params['trans']['body']
    file=session['file']
    session['content']=text
    schema = Kwalify::Yaml.load_file('config/locales/schemas/lang.schema.yml')
    validator = Kwalify::Validator.new(schema)
    parser = Kwalify::Yaml::Parser.new(validator)
    begin
      parser.parse(text)
      f=File.open(file, "w")
      f.write(text)
      redirect_to translations_path, notice: 'Translation file saved!'
    rescue Kwalify::SyntaxError => e
      flash[:error] = "SYNTAX ERROR: "+e.message+" Unable to save translation file!"
      redirect_to translations_path
    end
  end

  page_action :open, :method=>:post do
    file=session['file']=params['open_file']['file']
    if params['open_file']['content'].size < 2 || file != params['open_file']['recent_file']
      session['content']=File.open(file, "r").read
    else
      session['content']=params['open_file']['content']
    end
    redirect_to translations_path
  end


  content do
    panel "Translation" do 
      render 'index'
    end
  end
end
