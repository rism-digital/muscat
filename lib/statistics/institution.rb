module Statistics
  class Institution
    #Returns hash of institution => { siglum => count }
    def self.sources_per_date(from_date, to_date, institutions)
      result = ActiveSupport::OrderedHash.new
      s = Sunspot.search(::Source) do
        with(:created_at, from_date..to_date)
        facet(:lib_siglum, :limit => -1, :minimum_count => 10)
      end
      facet_rows = Hash.new(0)
      s.facet(:lib_siglum).rows.each do |r|
        facet_rows[r.value] = r.count
      end
      sigla = institutions.pluck(:siglum)
      facet_rows.each do |k,v|
        institution = ::Institution.where(:siglum => k).take
        next unless institution
        result[institution] = {k => v} if sigla.include?(k)
      end
      if !result.empty?
        return result
      else
        return {::Institution.first => {"ZERO" => 0}}
      end
    end
  end
end
