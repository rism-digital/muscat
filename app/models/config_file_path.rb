module ConfigFilePath
  # https://stackoverflow.com/questions/54485860/how-to-make-a-custom-method-that-can-be-used-anywhere-in-rails-app/54487749#54487749

  # Check if specific file exists, according to application.rb values;
  # if not, fallback to default, without further checking, as if the
  # default file is also missing it would require admin intervention.
  def self.get_marc_editor_profile_path(file)
    if File.exists? file
      file
    elsif file.include? "/#{RISM::MARC}/"
      file.sub "/#{RISM::MARC}/", "/default/"
    elsif file.include? "/#{RISM::EDITOR_PROFILE}/"
      file.sub "/#{RISM::EDITOR_PROFILE}/", "/default/"
    else
      file
    end
  end

end
