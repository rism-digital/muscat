# -*- encoding : utf-8 -*-
#
class IncipitsController < ApplicationController

  include BlacklightRangeLimit::ControllerOverride
  include BlacklightAdvancedSearch::Controller
  include Blacklight::Catalog
	include Blacklight::Configurable
  
  # FIXME for the autocomplete when needed
  #autocomplete :incipits, :id
  
  def info
    incipits = {}
    source = nil
    begin
      source = Source.find(params[:id])
    rescue ActiveRecord::RecordNotFound
    end
    
    if source
      source.marc.each_by_tag("031") do |t|
            
        subtags = [:a, :b, :c, :g, :n, :o, :p]
        vals = {}
      
        subtags.each do |st|
          v = t.fetch_first_by_tag(st)
          vals[st] = v && v.content ? v.content : "0"
        end

        next if vals[:p] == "0"

        pae_nr = "#{vals[:a]}.#{vals[:b]}.#{vals[:c]}"
      
        s = "@start:#{pae_nr}\n";
        s = s + "@clef:#{vals[:g]}\n";
        s = s + "@keysig:#{vals[:n]}\n";
        s = s + "@key:\n";
        s = s + "@timesig:#{vals[:o]}\n";
        s = s + "@data:#{vals[:p]}\n";
        s = s + "@end:#{pae_nr}\n"
      
        incipits[pae_nr] = s
      end
    end
    
    respond_to do |format|
      format.json { render json: incipits.to_json }
      format.html { render json: incipits.to_json }
    end
    
  end
  
  configure_blacklight do |config|
    # default advanced config values
    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search[:qt] ||= 'advanced'
    config.advanced_search[:url_key] ||= 'advanced'
    config.advanced_search[:query_parser] ||= 'incipit'
    config.advanced_search[:form_solr_parameters] ||= {}

    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = { 
      :qt => 'search',
      :"q.alt" => "*:*",
      :rows => 20,
      :defType => 'incipit',
      :hl => 'false',
    }
    
    # solr path which will be added to solr base url before the other solr params.
    #config.solr_path = 'select' 
    
    # items to show per page, each number in the array represent another option to choose from.
    config.per_page = [10,20,50,100]
    config.default_per_page = 20
    config.max_per_page = 20
    config.search_builder_class = IncipitSearchBuilder

    ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
    ## parameters included in the Blacklight-jetty document requestHandler.
    #
    config.default_document_solr_params = {
      :qt => 'document',
      ## These are hard-coded in the blacklight 'document' requestHandler
       :fl => '*',
       :rows => 1,
       :q => '{!raw f=id v=$id}' ,
      # Added by RZ
      :defType => 'edismax',
    }

    # solr field configuration for search results/index views
    config.index.title_field = 'id'
    config.index.display_type_field = 'id'
    # call out own partial index_header_rism_default
    # it could be called just index_header_default but this
    # way it implyies that it is customized
    #config.index.partials = [:index_header]
    config.add_index_field 'composer_ss', label: :filter_composer
    config.add_index_field 'title_ss', label: :filter_title
    config.add_index_field 'lib_siglum_ss', label: :lib_siglum

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

    #config.add_facet_field 'composer_ss', :label => 'Composer'
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
   
    
    config.add_search_field("id") do |field|
      field.label = "Incipit"
      field.solr_parameters = { :qf => "id" }
    end

    # "sort results by" select (pulldown)
    # label in pulldown is followed by the name of the SOLR field to sort by and
    # whether the sort is ascending or descending (it must be asc or desc
    # except in the relevancy case).
    config.add_sort_field 'score desc', :label => 'relevance'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

end 
