class ValidationExclusion

    def initialize(model)
        @model_object = model
        @model = model.to_s.underscore.downcase

        @config_base = "#{Rails.root}/config/validation_exclusions/#{@model}"
        @config_file = "#{@config_base}/exclusions.yml"

        @configuration = Hash.new

        load_configuration if File.exist?(@config_file)

    end

    def process_and_rule(item, rule_name, rule_val)
        if !rule_val.is_a? Array
            raise TypeError.new "Nested rule #{rule_name} must be an Array"
        end

        value = true
        rule_val.each do |rule|
            rule_arr = rule.first
            value &= parse_rule(item, rule_arr[0], rule_arr[1], true)
        end
        return value
    end

    def parse_rule(item, rule_name, rule_val, skip_and = false)
        if rule_name == "id_prefix"
            return true if item.id.to_s.start_with?(rule_val)
        elsif rule_name == "exclude_ids"
            return true if rule_val.include?(item.id.to_s)
        elsif rule_name == "creation_date"
            return true if item.created_at.to_date == DateTime.parse(rule_val).to_date
        elsif rule_name == "and_rules" && skip_and == false
            return true if process_and_rule(item, rule_name, rule_val)
        else
            "Unknown rule #{rule_name}"
        end
        return false
    end

    def exclude_from_tag?(tag, subtag, item)
        if !item.is_a? @model_object
            raise TypeError.new "Item validated is not a #{model}"
        end

        # No config present
        return false if @configuration.empty?

        # Tag not configured?
        return false if !@configuration["exclude"].include?(tag.to_s)
        # subtag not configured?
        return false if !@configuration["exclude"][tag.to_s]["tags"].include?(subtag.to_s)

        rules = @configuration["exclude"][tag.to_s]["tags"][subtag.to_s]

        rules.each do |rule|
            # split the key/val pair of the hash
            rule_arr = rule.first
            return true if parse_rule(item, rule_arr[0], rule_arr[1])
        end

        return false
    end

    private

    def load_exclusion_file(file_name)
        file_path = "#{@config_base}/#{file_name}"

        if !File.exist?(file_path)
            puts "Exclusion file not found: #{file_path}"
            return []
        end

        # load the IDS into an array
        ids = File.open(file_path).each_line.map {|l| l.strip} if File.exist?(file_path)
        return ids
    end

    def load_configuration
        @configuration = YAML::load(File.read(@config_file))
        @configuration[:calculated_excluded_ids] = {}

        @configuration["exclude"].each do |tag, tag_configuration|
            tag_configuration["tags"].each do |subtag, conf|
                conf.each do |config_element|
                    if config_element.include?("from_file_list")
                        list = []
                        # Load them from a file?
                        list.concat(load_exclusion_file(config_element["from_file_list"]))
                        list.sort!.uniq!
                        conf << {"exclude_ids" => list}
                    end
                end
            end
        end
    end


end