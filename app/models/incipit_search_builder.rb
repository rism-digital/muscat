class IncipitSearchBuilder < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
  self.default_processor_chain += [:add_search_type]

  def add_search_type(solr_parameters)
		
		pitch = @blacklight_params.include?(:pitch) ? @blacklight_params[:pitch] : "pi2"
		duration = @blacklight_params.include?(:duration) ? @blacklight_params[:duration] : "dur0"
		metric = @blacklight_params.include?(:metric) ? @blacklight_params[:metric] : "mw0"
		
		pitch = "pi2" if !pitch.match(/\bpi[123]\b/)
		duration = "dur0" if !duration.match(/\bdur[012]\b/)
		metric = "mw0" if !metric.match(/\bmw[012]\b/)
		
		solr_parameters[:match] = "#{pitch}#{metric}#{duration}"
		
	end


end