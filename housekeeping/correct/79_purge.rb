@params = {"order"=>"id_desc"}
@params[:per_page] = 20000

@model = Source
@model = ARGV[0].constantize if ARGV.count >= 1


def purge_set(hits)
    tot = 0
    hits.each do |hit|
        begin
            Source.find(hit.primary_key)
        rescue
            Sunspot.remove(Source) {with(:id, hit.primary_key)}
            #puts "Removed #{hit.primary_key} from index"
            tot += 1
        end
    end
    return tot
end

puts
puts "---------------------------------".yellow
puts " Purging #{@model} index".yellow
puts "---------------------------------".yellow
puts

total = 0

results, hits = @model.search_as_ransack(@params)
total += purge_set(hits)
Sunspot.commit

# insert the next ones
for page in 2..results.total_pages
  @params[:page] = page
  r, h = @model.search_as_ransack(@params)
  total += purge_set(h)
  Sunspot.commit
end

puts "Removed #{total} stale #{@model} SOLR index items"