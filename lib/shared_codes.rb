require 'yaml'

module SharedCodes
  class << self
    def get(list_name)
      all_lists[list_name.to_s]
    end

    def all_lists
      @all_lists ||= load_all
    end

    def reload!
      @all_lists = load_all
    end

    private

    def load_all
      lists = {}
      Dir[Rails.root.join("config/editor_profiles/shared_codes/*.yml")].each do |file|
        data = YAML.load_file(file)
        next unless data.is_a?(Hash)

        name = data["name"] || File.basename(file, ".yml")
        lists[name.to_s] = data["codes"]
      end
      lists
    end
  end
end