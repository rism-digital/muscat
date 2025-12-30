class MarcValidator
include ApplicationHelper
using AggressivelyStrip

  # test example:
  # MarcValidator.new(Source.first, nil, nil, nil, ValidationExclusion.new(Source)).validate_tags

  DEBUG = false

  def initialize(object, user = nil, warnings = false, logger = nil, exclusions = nil)
    @validation = EditorValidation.get_default_validation(object)
    @rules = @validation.rules
    @user = user
    @logger = logger
    @server_rules = @validation.server_rules
    @editor_profile = EditorConfiguration.get_default_layout(object)
    #ap @rules
    @errors = {}
    @object = object
    
    @exclusions = exclusions

    ## The marc could be already resolved
    ## Make a new safe internal version
    classname = "Marc" + object.class.to_s
    dyna_marc_class = Kernel.const_get(classname)
    @marc = dyna_marc_class.new(object.marc_source)
    
    # Parse the marc but don't read the foreign
    @marc.load_source false
    # Make the unresolved version
    @unresolved_marc = @marc.deep_copy
    @unresolved_marc.root = @marc.root.deep_copy
    # Now resolve
    @marc.root.resolve_externals
    
    @show_warnings = warnings
  end

  def validate_tags
    # Note: it can be possible that there is no validation to do
    # If there are no rules... do nothing
    @rules&.each do |tag, tag_rules|
      # 1. Determine mandatory subtags
      mandatory_subtags = extract_mandatory_subtags(tag, tag_rules)
      
      # 2. Check if the entire tag is missing when mandatory
      marc_tags = @marc.by_tags(tag)
      # This tag has to be there if "mandatory"
      next if entire_tag_missing_when_mandatory?(tag, marc_tags, mandatory_subtags)
      
      # 3. Validate each subtag rule
      validate_subtags_for_tag(tag, tag_rules, marc_tags)
    end
  end

  def extract_mandatory_subtags(tag, tag_rules)
    tag_rules["tags"].map do |st, v|
      if @exclusions&.exclude_from_tag?(tag, st, @object)
        puts "Downgrate #{tag} #{st} to non mandatory because of static exclusions" if DEBUG
        nil
      else
        # "next" is cool so it "returns" from the loop with the val
        next st if v == "mandatory" && !is_subtag_excluded(tag, st)
        # Also manage any_of mixed rules
        next st if v.is_a?(Hash) && v.keys.any?("any_of") && v.values.first.any?("mandatory") && !is_subtag_excluded(tag, st)
      end
    end.compact
  end
  
  def entire_tag_missing_when_mandatory?(tag, marc_tags, mandatory_subtags)
    if marc_tags.empty? && mandatory_subtags.any?
      add_error(tag, nil, I18n.t('validation.missing_message'))
      puts "Missing #{tag}, mandatory" if DEBUG
      return true
    end
    false
  end

  def validate_subtags_for_tag(tag, tag_rules, marc_tags)
    tag_rules["tags"].each do |subtag, rule|
      # Skip if subtag excluded
      if @exclusions&.exclude_from_tag?(tag, subtag, @object)
        puts "Skip #{tag} #{subtag} because of static exclusions" if DEBUG
        next
      end

      if is_subtag_excluded(tag, subtag)
        puts "Skip #{tag} #{subtag} because of tag_overrides" if DEBUG
        next
      end
      
      # We have to check each occurrence in marc_tags
      marc_tags.each_with_index do |marc_tag, index|
        marc_subtag = marc_tag.fetch_first_by_tag(subtag)
        validate_subtag_rule(tag, subtag, rule, marc_tag, marc_subtag)
      end
    end
  end

  def validate_subtag_rule(tag, subtag, rule, marc_tag, marc_subtag)
    # If rule is a simple string rule
    if rule.is_a?(String)
      validate_string_tag(rule, marc_tag, marc_subtag, tag, subtag)
      return
    end
  
    # If rule is a Hash, check sub-keys
    if rule.is_a?(Hash)
      validate_subtag_hash_rule(tag, subtag, rule, marc_tag, marc_subtag)
    end
  end
  
  def validate_subtag_hash_rule(tag, subtag, rule_hash, marc_tag, marc_subtag)
    # Each key in rule_hash might be "any_of", "begins_with", "required_if", etc.
    rule_hash.each do |key, value|
      case key
      when "any_of"
        # value is an array of subrules
        validate_any_of_rules(tag, subtag, value, marc_tag, marc_subtag)
  
      when "begins_with"
        validate_begins_with_rule(tag, subtag, marc_subtag, value)
  
      when "required_if"
        validate_required_if_rule(tag, subtag, marc_subtag, value)
      
      when "must_be_different"
        validate_must_be_different(tag, subtag, marc_subtag, value)

      when "must_contain"
        validate_must_contain_rule(tag, subtag, marc_subtag, value)
      else
        # Unknown rule or custom logic
        puts "Unknown rule key: #{key} => #{value.inspect}" if DEBUG
      end
    end
  end
  
  def validate_any_of_rules(tag, subtag, subrules, marc_tag, marc_subtag)
    subrules.to_a.each do |subrule|
      # If it does not pass, the whole any_of fails
      if !subrule_passes?(subrule, tag, subtag, marc_tag, marc_subtag)
        break
      end
    end
  
  end

  def subrule_passes?(subrule, tag, subtag, marc_tag, marc_subtag)
    old_error_count = @errors.size
  
    # Attempt validation
    validate_single_subrule(subrule, tag, subtag, marc_tag, marc_subtag)
  
    new_error_count = @errors.size
    # If no new errors => we consider it "passed"
    passed = (new_error_count == old_error_count)
  
    # Optional: if you *don't* want partial errors from each attempt,
    # you could revert any newly added errors. For example:
    # unless passed
    #   @errors = @errors.take(old_error_count)
    # end
  
    passed
  end

  def validate_single_subrule(subrule, tag, subtag, marc_tag, marc_subtag)
    if subrule.is_a?(String)
      # For a string rule like "required", "not_empty", etc.
      validate_string_tag(subrule, marc_tag, marc_subtag, tag, subtag)
    elsif subrule.is_a?(Hash)
      # Another hash rule, e.g. "begins_with" => "http"
      validate_subtag_hash_rule(tag, subtag, subrule, marc_tag, marc_subtag)
    else
      puts "Unknown subrule format: #{subrule.inspect}" if DEBUG
    end
  end

  def validate_begins_with_rule(tag, subtag, marc_subtag, required_prefix)
    if marc_subtag && marc_subtag.content && 
       !marc_subtag.content.start_with?(required_prefix)
      add_error(tag, subtag, "begin_with:#{required_prefix}")
      puts "#{tag} #{subtag} should begin with #{required_prefix}" if DEBUG
    end
  end

  def validate_must_contain_rule(tag, subtag, marc_subtag, substring)
    if marc_subtag && marc_subtag.content && 
       !marc_subtag.content.include?(substring)
      add_error(tag, subtag, "must_contain:#{substring}")
      puts "#{tag} #{subtag} must include the substring #{substring}" if DEBUG
    end
  end
  
  def validate_required_if_rule(tag, subtag, marc_subtag, required_if_rules)
    required_if_rules.each do |other_tag, other_subtag|
      other_marc_tag = @marc.first_occurance(other_tag)
      next unless other_marc_tag  # If not there, rule doesn't apply
      other_marc_subtag = other_marc_tag.fetch_first_by_tag(other_subtag)
      next unless other_marc_subtag&.content  # If no content, rule doesn't apply
  
      # Now we check if the current subtag is missing
      if marc_subtag.nil? || marc_subtag.content.blank?
        add_error(tag, subtag, "required_if-#{other_tag}#{other_subtag}")
        puts "Missing #{tag} #{subtag}, required_if-#{other_tag}#{other_subtag}" if DEBUG
      end
    end
  end

  def validate_must_be_different(tag, subtag, marc_subtag, rules)
    rules.each do |other_tag, other_subtag|
      other_marc_tag = @marc.first_occurance(other_tag)
      next unless other_marc_tag  # If not there, rule doesn't apply
      other_marc_subtag = other_marc_tag.fetch_first_by_tag(other_subtag)
      next unless other_marc_subtag&.content  # If no content, rule doesn't apply
  
      # Now we check if the current subtag is missing
      if marc_subtag.content == other_marc_subtag.content
        add_error(tag, subtag, "must_be_different-#{other_tag}#{other_subtag}")
        puts "Missing #{tag} #{subtag}, must_be_different-#{other_tag}#{other_subtag}" if DEBUG
      end
    end
  end

  def validate_links
    @marc.all_tags.each do |marctag|
      
      if !marctag
        add_error("missing-tag", nil, "foreign-tag: Master tag is absent in configuration", "link_error")
        next
      end

      foreigns = marctag.get_foreign_subfields
      next if foreigns.empty?
      
      master = marctag.get_master_foreign_subfield
      if !master
        add_error(marctag.tag, nil, "foreign-tag: missing_master", "link_error")
        next
      end

      unresolved_tags = @unresolved_marc.by_tags_with_subtag([marctag.tag], master.tag, master.content.to_s)

      if unresolved_tags.empty?
        add_error(marctag.tag, master.tag, "foreign-tag: Searching resolved master value in unresolved marc yields no results", "link_error")
        next
      end
      
      unresolved_tag = match_tags(marctag, unresolved_tags, foreigns)
      
      if !unresolved_tag
        add_error(marctag.tag, master.tag, "foreign-tag: Unable to find exach match in tags with multiple same master tags", "link_error")
        next
      end

      foreigns.each do |foreign_subtag|
        next if foreign_subtag.tag == master.tag #we already got the master

        if unresolved_tag.fetch_all_by_tag(foreign_subtag.tag).count > 1
          add_error(marctag.tag, foreign_subtag.tag, "foreign-tag: more than one foreign subtag", "link_error")
        end

        subtag = unresolved_tag.fetch_first_by_tag(foreign_subtag.tag) # get the first
        if subtag && subtag.content
          if subtag.content != foreign_subtag.content
            add_error(marctag.tag, foreign_subtag.tag, "foreign-tag: different unresolved value: #{subtag.content} from: ##{foreign_subtag.foreign_object.class}:#{foreign_subtag.foreign_object.id}", "link_error")
          end
        else
          add_error(marctag.tag, foreign_subtag.tag, "foreign-tag: tag not present in unresolved marc, from: ##{foreign_subtag.foreign_object.class}:#{foreign_subtag.foreign_object.id}", "link_error")
        end
      end
      
    end
  end
  
  def validate_dead_774_links
    @marc.each_by_tag("774") do |link|
      link_id = link.fetch_first_by_tag("w")
      link_type = link.fetch_first_by_tag("4")
      
      next if link_type && link_type.content && link_type.content == "holding"

      child = @object.get_child_source(link_id.content.to_i)
      add_error("stale-774", nil, "774_link: no db link to #{link_id.content}", "774_error") if !child
    end
  end

  def validate_dead_773_links
    # We should never have more than one 773 but here we are
    count = 0
    @marc.each_by_tag("773") do |link|
      count += 1
      link_id = link.fetch_first_by_tag("w")
      link_type = link.fetch_first_by_tag("4")
      
      next if link_type && link_type.content && link_type.content == "holding"

      begin
        parent = Source.find(link_id.content)
      rescue ActiveRecord::RecordNotFound
        add_error("deleted-773", nil, "773: parent deleted #{link_id.content}", "773_error")
      end

      found = false
      parent.marc.each_by_tag("774") do |parent_774|

        parent_link_id = parent_774.fetch_first_by_tag("w")
        next if !parent_link_id || !parent_link_id.content

        if @object.id.to_i == parent_link_id.content.to_i
          found = true
          break
        end
      end

      add_error("stale-773", nil, "773: missing 774 tag in parent #{link_id.content}", "773_error") if !found
    end

    add_error("multiple-773", nil, "773: More than one", "773_error") if count > 1
  end

  def validate_dates
    
    @marc.each_by_tag("260") do |marctag|
      marctag.each_by_tag("c") do |marcsubtag|
        next if !marcsubtag || !marcsubtag.content
        dates = []
        dates = date_to_array(marcsubtag.content, false)
        
        next if dates.count == 0
        dates.sort!.uniq!

        max = min = dates[0].to_i
        
        if dates.count > 1
          max = dates.last.to_i
          min = dates.first.to_i
        end
        
        # Make a warning for a year n the future
        # I can be legitimate, like a forthcoming publication
        if max > Date.today.year
          add_error("260", "c", "Date in the future: #{max} (#{marcsubtag.content})", "date_error")
        end
        
        # Make a warning if it is before the 11th century
        # we have sources in the 11th century
        if min < 1000
          add_error("260", "c", "Date too far in the past: #{min} (#{marcsubtag.content})", "date_error")
        end
      end
    end
  end

  def validate_server_side
    if @server_rules
      @server_rules.each do |rule|
        self.send(rule) rescue next
      end
    end
  end

  def validate_unknown_tags
    @unknown_tags = []
      @editor_profile.each_tag_not_in_layout(@object) do |t|
        add_error(t, "unknown-tag", "Unknown tag in layout", "unknown_tag_error")
      end
  end

  def validate_holdings
    return if !@object.is_a?(Source)

    if @object.record_type == MarcSource::RECORD_TYPES[:edition]
      add_error("record", "holdings", "No holding records", "holding_error") if @object.holdings.empty?
    elsif @object.record_type == MarcSource::RECORD_TYPES[:edition_content] ||
      @object.record_type == MarcSource::RECORD_TYPES[:theoretica_edition_content] ||
      @object.record_type == MarcSource::RECORD_TYPES[:libretto_edition_content]
      add_error("record", "holdings", "#{@object.get_record_type} should not have holding records", "holding_error") if !@object.holdings.empty?
      add_error("record", "holdings", "#{@object.get_record_type} must have a parent", "holding_error") if !@object.parent_source
    end
  end

  # This works only for sources
  def validate_parent_institution
    return if !@object.is_a?(Source)
    return if !@object.parent_source

    # The two libraries must match, so report if one is missing
    parent_id = nil
    source_id = nil

    parent_relations = SourceInstitutionRelation.where(source_id: @object.parent_source, marc_tag: "852")
    parent_id = parent_relations.first.institution_id if !parent_relations.empty?

    source_relations = SourceInstitutionRelation.where(source_id: @object.id, marc_tag: "852")
    source_id = source_relations.first.institution_id if !source_relations.empty?

    if parent_id != source_id
      add_error("record", "institution", "Child institution differes from parent (c=#{source_id} p=#{parent_id})", "parent_institution_error")
    end
  end

  def validate_588
    return if !@object.respond_to?(:holdings) || @object.holdings.count == 0
    return if @object.marc.by_tags("588").count == 0

    holdings_sigla = @object.holdings.map(&:lib_siglum)

    @object.marc.each_by_tag("588") do |t|
      # There should be only one of these...
      t.fetch_all_by_tag("a").map(&:content).compact.each do |content|
        # Extract the first chunk as the siglum
        siglum = content.split(" ").first
        
        #siglum_pattern = /\b[A-Z]{1,3}-[\p{L}\p{M}]+\b/u
        siglum_pattern_nopunct = /\b[A-Z]{1,3}-[\p{L}\p{M}]+(?=\s|$)/u
        matches = content.scan(siglum_pattern_nopunct)

        matches.each do |match|
          unless holdings_sigla.include?(match)
            add_error("588", "a", "siglum_not_found:#{siglum}", "source_description_missing")
          end
        end

        add_error("588", "a", "invalid_siglum:#{siglum}", "source_description_missing") if matches.count == 0

      end
    end
    

  end

  def validate_work_status
    return if !@object.is_a?(Work)

    # No work is published unless belonging to a publication with work_catalogue 2, 3 or 4
    if @object.wf_stage == "published"
      
      @object.publications.each do |p|

        if p.wf_stage != "published" 
          add_error("record", "work", "Published work is attached to an unpublished publication", "work_to_unpublished_publication")
        end

        if !p.work_catalogue || p.work_catalogue == "not_work_catalogue" ||  p.work_catalogue == "work_catalogue_in_preparation"
          wc = p.work_catalogue ? p.work_catalogue.to_s : "not_set"
          add_error("record", "work", "Work is attached to a non complete work catalog (wc=#{wc})", "work_to_non_work_catalog")
        end
      end

    # All works for a publication with work_catalogue 2, 3 or 4 are published
    # eg. work is unpublished, should not be attached to finished catalogs!
    else 
      @object.publications.each do |p|
        if p.work_catalogue != "not_work_catalogue" &&  p.work_catalogue != "work_catalogue_in_preparation"
          add_error("record", "work", "Work unpublished but attached to a completed catalog (wc=#{p.work_catalogue})", "work_unpublished_in_catalog")
        end
      end

    end

  end

  def validate
    validate_tags
    validate_dates
    validate_links
    validate_holdings
    validate_unknown_tags
    validate_dead_774_links
    validate_dead_773_links
    validate_parent_institution
    validate_588
    validate_work_status
    return @errors
  end

  def has_errors
    return @errors.count > 0
  end
  
  def get_errors
    @errors
  end

  def current_user
    @user
  end

  def to_s(options = {})
    output = ""
    @errors.each do |tag, subtags|
      subtags.each do |subtag, messages|
        messages.each do |message|
          loc_message = message
          if options.fetch(:translate, true)
            message = "no_subtag" if subtag == "no_subtag"
            sanit_message = message.split("-").first.split(":").first
            label = "backend_validation." + sanit_message
            if I18n.exists?(label)
              loc_message = I18n.t(label) + " [#{message}]"
            else
              # This happens in some backend-generatet errors
              loc_message = message
            end
          end
          output += "#{@object.id}\t#{tag}\t#{subtag}\t#{loc_message}\n"
        end
      end
    end
    output
  end
  
  private
  
  def validate_string_tag(rule, marc_tag, marc_subtag, tag, subtag)
    if rule == "required" || rule == "required, warning" || rule == "mandatory"
      if !marc_subtag || !marc_subtag.content
        #@errors["#{tag}#{subtag}"] = rule
        add_error(tag, subtag, rule) if (!@validation.is_warning?(tag, subtag) || @show_warnings)
        puts "Missing #{tag} #{subtag}, #{rule}" if DEBUG
      end
    elsif rule == "uniq"
      binding.pry
    elsif rule == "check_group"
      grp_index = marc_tag.fetch_first_by_tag("8")
      if grp_index && grp_index.content
        if grp_index.content.to_i == 1 && marc_subtag && marc_subtag.content && marc_subtag.content == "Additional printed material"
          add_error(tag, subtag, rule)
          puts "The first material group cannot be \"Additional printed material\"" if DEBUG
        end
      else
        add_error(tag, subtag, "not_in_group")
        puts "check_group requested but tag is not in a group #{tag}#{subtag}" if DEBUG
      end
    elsif rule == "validate_588_siglum"
      siglum_pattern_nopunct = /\b[A-Z]{1,3}-[\p{L}\p{M}]+(?=\s|$)/u
      if marc_subtag && marc_subtag.content
        if !marc_subtag.content.match(siglum_pattern_nopunct)
          add_error(tag, subtag, rule)
          puts "588 does not have a valid sigla #{tag} #{subtag}, #{rule}" if DEBUG
        end
      end
    elsif rule == "validate_031_dups"
        ## A 031 MAY but should not have an epty a, b or c
        # if it is emmpty let it all fail and set an error
        begin 
          my_id = [marc_tag["a"].first.content, marc_tag["b"].first.content, marc_tag["c"].first.content].join(".")
        rescue
          add_error(tag, subtag, "031_incomplete")
          puts "The current 031 is missimt $a, $b or $c #{tag} #{subtag}, #{rule}" if DEBUG
          return
        end

        # Also other 031 can be empty
        begin
          all_ids = @marc["031"].map {|m31| [m31["a"].first.content, m31["b"].first.content, m31["c"].first.content].join(".")}
          if all_ids.count(my_id) > 1
            add_error("#{tag}-#{my_id}", subtag, rule)
            puts "The current 031 id is duplicated #{tag} #{subtag}, #{rule}" if DEBUG
          end
        rescue
          return
        end
    elsif rule == "validate_url"
        
        def http_url?(input)
          uri = URI.parse(input.to_s)
          uri.is_a?(URI::HTTP) && %w[http https].include?(uri.scheme)
        rescue URI::InvalidURIError
          false
        end
        
        if marc_subtag && marc_subtag.content
          # Strip does not strip the unicode flavour of space
          if !(http_url?(marc_subtag.content.aggressively_strip.strip))
            add_error(tag, subtag, rule)
            puts "The URL in #{tag} #{subtag} is invalid [#{marc_subtag.content}], #{rule}" if DEBUG
          end
        end
    elsif rule == "not_record_id"
      return if !@marc.respond_to? :get_id
      return if !marc_subtag
      return if !marc_subtag.content

      record_id = @marc.get_id&.to_s&.strip
      subtag_id = marc_subtag&.content&.to_s&.strip

      return if record_id.nil? || record_id.empty?
      return if subtag_id.nil? || subtag_id.empty?

      if record_id == subtag_id
          add_error(tag, subtag, rule)
          puts "The ID for tag #{tag} cannot be the record id #{@object.id}" if DEBUG
      end
    else
      puts rule.class
      puts "Unknown rule #{rule}" if rule != "mandatory"
    end
  end

  def match_tags(marctag, unresolved_tags, foreigns)
    exclude_subfields = foreigns.collect {|s| s.tag}
    found = true
    #ap "========================="
    #ap marctag
    unresolved_tags.each do |utag|
      #ap "-----------------------"
      #ap utag
      marctag.children do |resolved_subtag|
        subtag_found = false
        # The linked subfields are analyzed afterwards
        # Here we make sure that *all* the fields match
        next if exclude_subfields.include?(resolved_subtag.tag)
        # We can have scattered subtags in random order
        # Should not happen but...
        utag.each_by_tag(resolved_subtag.tag) do |usubtag|
          subtag_found = true if usubtag.content == resolved_subtag.content
          #puts usubtag.content
          #ap resolved_subtag.content
        end
        
        found &= subtag_found
      end
      #ap found
      return utag if found
      found = true
    end
    nil
  end
  
  def add_error(tag, subtag, message, log_tag = nil)
    tag = "no_tag" if !tag
    subtag = "no_subtag" if !subtag
    @errors[tag] = {} if !@errors.has_key?(tag)
    @errors[tag][subtag] = [] if !@errors[tag].has_key?(subtag)
    
    @errors[tag][subtag] << message
    
    log_tag = "validation_error" if !log_tag
    @logger.error("#{log_tag} #{@object.id} #{print_record_type(@object)} #{tag} #{subtag} #{message}") if @logger
  end
  
  def is_subtag_excluded(tag, subtag)
        
    # Skip tags based on configuration
    # i.e. collections have different tags
    tag_overrides = @rules[tag]["tag_overrides"]
    if tag_overrides && tag_overrides["exclude"][subtag]
      # FIXME! This will not work for other models
      if tag_overrides["exclude"][subtag].include?(@object.get_record_type.to_s)
        return true
      end
    end
    return false
  end
  
  # SERVER VALIDATION
  #User should not be able to create or save record from foreign library
  def validate_user_abilities
    return if @user.has_role?(:admin) || @user.has_role?(:editor)
    return if !@marc.get_siglum
    sigla = []
    @user.workgroups.each do |w|
      sigla.push(*w.get_institutions.pluck(:siglum))
    end
    unless sigla.include?(@marc.get_siglum)
      add_error("852", "", I18n.t('validation.insufficient_rights'))
    end
  end

  # Name of publication entry should be uniq
  def validate_name_uniqueness
    short_title = @marc.get_name
    return false if short_title.blank?
    cat = Publication.where.not(id: @marc.get_id).where(name: short_title).take
    if cat
      add_error("210", "", I18n.t('validation.name_uniqueness'))
    end
  end

  def validate_links_to_self
    {"773": "w", "787": "w", "775": "w", "596": "c"}.each do |tag, st|
      t = tag.to_s
      val = @marc.first_occurance(t.to_s, st)

      next if (!val || !val.content)
      next if !@marc.get_id

      if @marc.get_id.to_i == val.content.to_i
        add_error(t, "w", I18n.t('validation.cannot_link_to_self', id: @marc.get_id)) 
      end
    end
  end

  def print_record_type(item)
    if item.respond_to?(:get_record_type)
      return item.get_record_type.to_s
    else
      return "none"
    end
  end

end
