module Statistics
  class Publication

    #Return the percentage of works attached missing incipit (e.g. 25 for a 1/4 of works without incipit)
    def self.works_statistics(publication)
      res = { :incipits => 100, :dnb => 100  }

      return res if (publication.referring_works.size == 0)
      incipits = 0
      dnb = 0
      publication.referring_works.each do |w|
        w.marc.load_source false
        incipits += 1 if w.marc.has_incipits?
        dnb += 1 if w.marc.has_link_to?("DNB")
      end
      res[:incipits] = 100 - (incipits * 100 / publication.referring_works.size)
      res[:dnb] = 100 - (dnb * 100 / publication.referring_works.size)
      ap res
      return res
    end
  end
end