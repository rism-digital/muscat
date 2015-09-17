class MarcSearch

  def self.select(model, marcfield, term)
    raise "Marcfield parameter should contain dollar sign (e.g. '100$a')" if !marcfield.include?('$')
    tag = marcfield.split('$')[0]
    code = marcfield.split('$')[1]
    marcfield = marcfield.gsub("$", "")
    result = Hash.new
    search = model.solr_search do
      fulltext(term, :fields => [marcfield])
      paginate :per_page => 50
    end
    search = model.solr_search do
      fulltext(term, :fields => [marcfield])
      paginate :per_page => search.total
    end
    puts search.total
    search.results.each do |marc|
      result[marc] = ""
    end
    result.each do |key, value|
      marc = key.marc
      begin
      marc.each_by_tag(tag) do |t|
        result[key] = t.fetch_first_by_tag(code).content
      end
      # if for whatever reason the record is dropped from db, but in index
      rescue Exception
        puts key.id
      end
    end
    result

  end

  def self.fields(model)
    IndexConfig.get_fields(model)
  end

end

