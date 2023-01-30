module Statistics
  class User
    # Returns hash of person => {:month => size}
    def self.by_month(from_date, to_date, users, klass = "Source")
      result = ActiveSupport::OrderedHash.new
      time_range = ApplicationHelper.month_distance(from_date, to_date)
      users.each do |user|
        #s = Sunspot.search(klass) do
        s = klass.constantize.solr_search() do
          with(:created_at, from_date..to_date)
          with(:wf_owner, user.id)
          facet(:created_at, :zeros => true) do
            time_range.each do |distance|
              start_time = Time.now.beginning_of_month + distance.month
              row start_time.localtime.strftime("%Y-%m") do
                with :created_at, start_time..start_time.end_of_month
              end
            end
          end
        end
        line = ActiveSupport::OrderedHash.new
        s.facet(:created_at).rows.each do |r|
          line[r.value] = r.count
        end   
        result[user] = line
      end
      return result
    end

    def self.sources_by_month(from_date, to_date, users)
      self.by_month(from_date, to_date, users, "Source")
    end

    def self.holdings_by_month(from_date, to_date, users)
      self.by_month(from_date, to_date, users, "Holding")
    end

  end
end
