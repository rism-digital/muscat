# -*- encoding : utf-8 -*-
#
class CatalogController < ApplicationController  

  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller
  include Blacklight::Catalog
  
  DEFAULT_FACET_LIMIT = 20
  
  before_action :redirect_legacy_values, :only => :show
  before_action :save_controller
     
  protect_from_forgery :except => [:holding]

  def save_controller
    #save the actual controller name
    suffix = params[:controller].split("_")
    @catalog_controller = suffix.count > 1 ? suffix.last : nil
  end
  
  def facet_list_limit
  	if defined? @default_limit
      @default_limit
    else
      DEFAULT_FACET_LIMIT + 1
    end
  end

  def make_geoterm
    out = []
    noinfo_sources = 0
    noinfo_libraries = 0
    total = 0
  
    @pagination.items.each do |item|
      total += item[:hits]
      lib = Institution.find_by_siglum(item[:value])
      if !lib
        noinfo_sources += item[:hits]
        noinfo_libraries +=1
        next
      end
      
      marc = lib.marc
      marc.load_source false
      lat = marc.first_occurance("034", "f")
      lon = marc.first_occurance("034", "d")
      
      lat = (lat && lat.content) ? lat.content : 0
      lon = (lon && lon.content) ? lon.content : 0
      
      # If the info is not there, skip it
      if lat == 0 || lon == 0
        noinfo_sources += item[:hits]
        noinfo_libraries +=1
        next
      end
      
      out << {
        name: item[:value],
        weight: item[:hits],
        lon: lon,
        lat: lat,
        description: lib.name,
        place: lib.place
      }
    end
    
    {info: {noinfo_libraries: noinfo_libraries, noinfo_sources: noinfo_sources, total: total, unique_sources: @response[:response]["numFound"]},
     data: out
    }
  end

  def geosearch
    #if params.include? :map
      @default_limit = 100000
      #else
    #  @default_limit = DEFAULT_FACET_LIMIT
    #end
    #facet
    
    @facet = blacklight_config.facet_fields[params[:id]]
    @response = get_facet_field_response(@facet.key, params)
    @display_facet = @response.aggregations[@facet.key]

    @pagination = facet_paginator(@facet, @display_facet)

    respond_to do |format|
      format.json { render json: make_geoterm }
    end
    
    @default_limit = DEFAULT_FACET_LIMIT
  end

  
  def render_search_results_as_json_disable
    out = []
    @document_list.each do |item|
      
      latlon = item[:location_lls]
      lat, lon = latlon.split(",")

      out << {
        id: item[:id],
        description: item[:lib_siglum_ss],
        name: item[:std_title_texts].first,
        #weight: item[:hits],
        lon: lon,
        lat: lat
      }
    end
    out
  end
  
  def redirect_legacy_values
    # Rewrite old IDS with five leading zeros
    if params[:id].start_with?('00000')
      params[:id] = params[:id][5, params[:id].length]
    end
    params[:id] = "Source " + params[:id]
  end

  def mei
    @item = Source.find(params[:id])
  end
  
  def holding
    opac = (params[:opac] == "true")
    
    @item = Holding.find( params[:object_id] )
    
    begin
      @item.marc.load_source(true)
    rescue ActiveRecord::RecordNotFound
      puts "Could not properly load MarcHolding #{@item.id}"
    end
    
    @editor_profile = EditorConfiguration.get_show_layout @item
    
    render :template => 'marc_show/show_preview', :locals => { :opac => opac, :holdings => true }
  end
  
  def download_xslt
    send_file(
      "#{Rails.root}/public/xml/marc2mei.xsl",
      filename: "marc2mei.xsl",
      type: "text/xsl"
    )
  end
  
  def download
    if params.include?(:email) && !params[:email].empty?
      # run the job
      if !verify_recaptcha # Make sure the user verified the captcha
        render template: "catalog_download/download"
      else
        format = params.include?(:out_format) && params[:out_format] == "csv" ? :csv : :xml

        Delayed::Job.enqueue(ExportRecordsJob.new(:catalog, {search_params: params.permit!.to_hash, email: params[:email], format: format, controller: @catalog_controller}))
        render template: "catalog_download/confirm"
      end
    else
      render template: "catalog_download/download"
    end
  end

  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'edismax'
    config.advanced_search[:form_solr_parameters] ||= {}

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = { 
      :qt => 'search',
      :"q.alt" => "*:*",
      :rows => 20,
      :defType => 'edismax',
      :fq => "+type:Source +wf_stage_s:published",
      :hl => 'false',
      :"hl.simple.pre" => '<span class="highlight">',
      :"hl.simple.post" => "</span>",
      :"facet.mincount" => 1,
    }
    
    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select' 
    
    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [10,20,50,100]
    config.default_per_page = 20
    config.max_per_page = 20000000

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      ## These are hard-coded in the blacklight 'document' requestHandler
       :fl => '*',
       :rows => 1,
       :q => '{!raw f=id v=$id}' ,
    }

    # solr field configuration for search results/index views
    #config.index.title_field = 'std_title_texts'
    # Set it as in RISM A/2 OPAC
    config.index.title_field = 'std_title_texts'
    config.index.display_type_field = 'composer_order_s'
    # call out own partial index_header_rism_default
    # it could be called just index_header_default but this
    # way it implyies that it is customized
    config.index.partials = [:index_header_rism]
    config.add_index_field 'source_title_field',   :accessor => 'source_index_description'
    config.add_index_field 'source_composer_field',   :accessor => 'source_index_composer'

    # solr field configuration for document/show views
    #config.show.title_field = 'title_display'
    #config.show.display_type_field = 'format'

    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.  
    #
    # :show may be set to false if you don't want the facet to be drawn in the 
    # facet bar
    config.add_facet_field 'std_title_order_s', :label => :filter_std_title, :limit => 10
    config.add_facet_field 'composer_order_s', :label => :filter_composer, :limit => 10
    config.add_facet_field '593a_filter_sm', :label => :filter_source_type, :limit => 10
    config.add_facet_field '240m_filter_sm', :label => :filter_scoring, :limit => 10
    ##config.add_facet_field '240m_sms', :label => 'Publisher', :limit => 10, solr_params: { 'facet.mincount' => 1 }
    config.add_facet_field '260c_year_ims', :label => :filter_date, :range => true, :limit => 5
    config.add_facet_field '852a_facet_sm', :label => :filter_lib_siglum, :limit => 10
    config.add_facet_field '650a_filter_sm', :label => :filter_subject, :limit => 10
    config.add_facet_field '856x_sm', :label => :filter_images, :limit => 10
    config.add_facet_field 'copies_is', :label => :filter_printed_exemplars, :range => true, :limit => 10
    #config.add_facet_field 'title_order', :label => 'Standard Title', :single => true
    #config.add_facet_field 'subject_topic_facet', :label => 'Topic', :limit => 20 
    #config.add_facet_field 'language_facet', :label => 'Language', :limit => true 
    #config.add_facet_field 'lc_1letter_facet', :label => 'Call Number' 
    #config.add_facet_field 'subject_geo_facet', :label => 'Region' 
    #config.add_facet_field 'subject_era_facet', :label => 'Era'  

    #config.add_facet_field 'example_pivot_field', :label => 'Pivot Field', :pivot => ['format', 'language_facet']

    #config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
    #   :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
    #   :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
    #   :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
    #}


    # Have BL send all facet field names to Solr, which has been the default
    # previously. Simply remove these lines if you'd rather use Solr request
    # handler defaults, or have no facets.
    config.add_facet_fields_to_solr_request!

    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display
    # configured above

    # solr fields to be displayed in the show (single result) view
    #   The ordering of the field names is the order of the display 
    #config.add_show_field 'title_vern_display', :label => 'Title'
    #config.add_show_field 'subtitle_display', :label => 'Subtitle'
    #config.add_show_field 'subtitle_vern_display', :label => 'Subtitle'
    #config.add_show_field 'author_display', :label => 'Author'
    #config.add_show_field 'author_vern_display', :label => 'Author'
    #config.add_show_field 'format', :label => 'Format'
    #config.add_show_field 'url_fulltext_display', :label => 'URL'
    #config.add_show_field 'url_suppl_display', :label => 'More Information'
    #config.add_show_field 'language_facet', :label => 'Language'
    #config.add_show_field 'published_display', :label => 'Published'
    #config.add_show_field 'published_vern_display', :label => 'Published'
    #config.add_show_field 'lc_callnum_display', :label => 'Call number'
    #config.add_show_field 'isbn_t', :label => 'ISBN'

    # "fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields
    #
    # Search fields will inherit the :qt solr request handler from
    # config[:default_solr_parameters], OR can specify a different one
    # with a :qt key/value. Below examples inherit, except for subject
    # that specifies the same :qt as default for our own internal
    # testing purposes.
    #
    # The :key is what will be used to identify this BL search field internally,
    # as well as in URLs -- so changing it after deployment may break bookmarked
    # urls.  A display label will be automatically calculated from the :key,
    # or can be specified manually to be different. 

    # This one uses all the defaults set by the solr request handler. Which
    # solr request handler? The one set in config[:default_solr_parameters][:qt],
    # since we aren't specifying it otherwise. 
    
    #config.add_search_field('author') do |field|
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'author' }
    #  field.solr_local_parameters = { 
    #    :qf => '$author_qf',
    #    :pf => '$author_pf'
    #  }
    #end
    
    # Specifying a :qt only to show it's possible, and so our internal automated
    # tests can test it. In this case it's the same as 
    # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
    #config.add_search_field('subject') do |field|
    #  field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
    #  field.qt = 'search'
    #  field.solr_local_parameters = { 
    #    :qf => '$subject_qf',
    #    :pf => '$subject_pf'
    #  }
    #end
    
    config.add_search_field('any_field') do |field|
      field.label = :filter_any_field
      # Dumb was here
      field.solr_parameters = { 
        # THIS IS THE HACK OF THE DAY
        #FIXME FIXME FIXME
        :qf => 'textSpell'  
      }
    end
    
    config.add_search_field('composer') do |field|
      field.label = :filter_composer
      field.solr_parameters = { 
        :qf => 'composer_texts',
      }
    end

    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title_all') do |field|
      field.label = :filter_title
      field.include_in_advanced_search = false # This is only for the topbar
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      #field.solr_parameters = { :'spellcheck.dictionary' => 'title_d_text' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_parameters = { 
        :qf => 'title_texts std_title_texts',
      }
    end

    # Add some filters for the adv search
    config.add_search_field("title") do |field|
      field.label = :filter_title_on_ms
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "title_texts" }
    end

    # Add some filters for the adv search
    config.add_search_field("genre") do |field|
      field.label = :filter_std_title
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "std_title_texts" }
    end
    config.add_search_field("publisher") do |field|
      field.label = :publisher
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "publisher_texts" }
    end

    config.add_search_field("plate_no") do |field|
      field.label = :filter_plate_no
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "028a_text" }
    end

    config.add_search_field("provenance") do |field|
      field.label = :filter_provenance
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "561a_text" }
    end
    
    config.add_search_field("source_type") do |field|
      field.label = :filter_source_type
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "593a_texts" }
    end
    
    config.add_search_field("liturgical_feast") do |field|
      field.label = :filter_liturgical_feast
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "657a_text" }
    end
    
    config.add_search_field("institution") do |field|
      field.label = :filter_institution
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "110a_test" }
    end
    
    config.add_search_field("publication") do |field|
      field.label = :filter_publications
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "690a_text" }
    end
    
    config.add_search_field("scoring") do |field|
      field.label = :filter_scoring
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "240m_texts" }
    end
    
    # This is shown in the topbar
    config.add_search_field("library_siglum") do |field|
      field.label = :filter_lib_siglum
      field.solr_parameters = { :qf => "852a_text" }
    end
    
    config.add_search_field("rism_id_no") do |field|
      field.label = :filter_id
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "id_i" }
    end
    
    config.add_search_field("year") do |field|
      field.label = :filter_date
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "date_from_i" }
    end
    
    config.add_search_field("shelfmark") do |field|
      field.label = :filter_shelf_mark
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "852c_texts" }
    end
    
    config.add_search_field("language") do |field|
      field.label = :filter_language
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "041a_text" }
    end

    # Show in topbar too
    config.add_search_field("subject") do |field|
      field.label = :filter_subject
      field.solr_parameters = { :qf => "650a_text" }
    end
    
    config.add_search_field("pae") do |field|
      field.label = "Incipit"
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "pae" }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'std_title_order_s asc', :label => :filter_std_title;
    config.add_sort_field ':date_from_i asc', :label => :filter_date;
    config.add_sort_field ':composer_order_s asc', :label => :filter_composer;
    #config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    #config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
    #config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    #config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

end 
