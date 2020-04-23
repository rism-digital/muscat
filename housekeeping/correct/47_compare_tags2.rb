require 'net/http'

URL = "http://dev.muscat-project.org/catalog/"

check_added = false

pb = ProgressBar.new(Source.all.count)

Source.all.each do |orig_source|
    pb.increment!
    m = Net::HTTP.get(URI(URL + "#{orig_source.id}.txt"))

    marc = MarcSource.new(m)
    marc.load_source(false)

    big_muscat = {}
    small_muscat = {}

    marc.each_by_tag("651") do |t|
        first = ""
        id1 = 0
        st = t.fetch_first_by_tag("a")
        if st && st.content
          first = st.content.force_encoding("UTF-8")
        end

        st = t.fetch_first_by_tag("0")
        if st && st.content
          id1 = st.content.to_i
        end

        big_muscat[id1] = first #if id1
    end

    orig_source.marc.each_by_tag("651") do |t|
      id2 = 0
      second = ""

      st = t.fetch_first_by_tag("0")
      if st && st.content
        id2 = st.content.to_i
      end

      st = t.fetch_first_by_tag("a")
      if st && st.content
        second = st.content.force_encoding("UTF-8")
      end

      small_muscat[id2] = second #if id2

    end

    next if big_muscat.keys[0] == small_muscat.keys[0]

    #next if first == "x"
    next if big_muscat.empty?
    next if big_muscat.keys[0] == 0
    small_muscat = {0 => ""} if small_muscat.empty?
    #if first != second
    #puts big_muscat.to_s + "\t" + small_muscat.to_s

    #puts "http://admin.rism-ch.org/admin/sources/#{orig_source.id}\thttps://muscat.rism.info/admin/sources/#{orig_source.id}\t#{big_muscat.first}\t#{small_muscat.first}"

    puts big_muscat.keys[0].to_s + "\t" + big_muscat[big_muscat.keys[0]] + "\t" + small_muscat.keys[0].to_s + "\t" + small_muscat[small_muscat.keys[0]]

        #puts "#{first.to_s}\t#{id1}\t#{second.to_s}\t#{id2}"
   # end
end