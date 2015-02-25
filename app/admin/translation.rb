ActiveAdmin.register_page "Translations" do
  menu :parent => "admin_menu", :if => proc{ can? :manage, :all }
  files=['en.yml', 'de.yml', 'fr.yml', 'it.yml']

  page_action :trans, :method=>:post do
    puts params
    text=params['trans']['body']
    file=session['file']
    f=File.open("config/locales/"+file, "w")
    f.write(text)
    redirect_to translations_path
  end

  page_action :open, :method=>:post do
    puts params
    session['file']=params['open_file']['file']
    redirect_to translations_path
  end


  content do
    panel "Translation" do 
      render 'index', :files => files
    end
  end
end
