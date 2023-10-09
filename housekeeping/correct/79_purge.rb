@params = {"order"=>"id_desc"}
@params[:per_page] = 20000

@model = Source
@model = ARGV[0].constantize if ARGV.count >= 1

def find_orphans(hits)
    to_purge = []

    hits.each do |hit|
        begin
            @model.find(hit.primary_key)
        rescue ActiveRecord::RecordNotFound
            to_purge << hit.primary_key
        end
    end

    return to_purge
end

def delete_all(ids)
    ids.each_slice(500) do |slice|
        Sunspot.remove(@model) {with(:id, slice)}
    end
end

total_ids = []

begin_time = Time.now

results, hits = @model.search_as_ransack(@params)
total_ids += find_orphans(hits)

# insert the next ones
for page in 2..results.total_pages
  @params[:page] = page
  r, h = @model.search_as_ransack(@params)
  total_ids += find_orphans(h)
end

delete_all(total_ids)
Sunspot.commit

end_time = Time.now

puts "#{@model}: removed #{total_ids.count} stale SOLR index items (#{end_time - begin_time} seconds run time)"