def marc2csv(source)
=begin
RISM ID
RISM-Sigel und Signatur (852 $a und 852 $c)
2a) Bei Drucken: Nur 852$a (maximal 3, ansonsten Anzahl der Exemplare, Bsp. EN: 10 copies / ES 10 ejemplares)
Übergeordneter Eintrag (773) (Teil in: / Part of: / Parte de:)
[fett:] Komponist (100 $a)
Einordnungstitel (240 $a, 240 $o, 240 $k, 240 $r, 240 $m)
5.1) [kursiv:] Diplomatischer Titel? (245 $a), begrenzt auf 120 Zeichen mit Auslassungszeichen am Ende “...”, wenn länger.
Werkverzeichnis: Lit.kürzel plus WV-Nr. (690 $a, 690 $n)
Schlagworteintragung (650 $a)
Quellentyp (593 $a)
Jahr (260 $c)
9a) Bei Drucken: auch 260 $a, b
Material (300 $a)
Bei Drucken: Plattennummer (028)
=end
    csv_line = {}
    
    csv_line[:record_id] = source.id

    if source.holdings.count > 0
        signature = []
        source.holdings.each do |h|
            h.marc.each_by_tag("852") do |t|
                ta = t.fetch_first_by_tag("a").content rescue ta = ""
                tc = t.fetch_first_by_tag("c").content rescue tc = ""

                signature << ta + " " + tc
            end
        end
        csv_line[:signature] = signature.join("\n")
        csv_line[:copies] = ""
    else
        csv_line[:signature] = source.lib_siglum + " " + source.shelf_mark
        csv_line[:copies] = ""
    end

    if source.parent_source
        csv_line[:in] = source.parent_source.id
    else
        csv_line[:in] = ""
    end

    csv_line[:composer] = source.composer
    csv_line[:title] = source.title
    csv_line[:standard_title] = source.std_title

    literature = []
    source.marc.each_by_tag("690") do |t|
        ta = t.fetch_first_by_tag("a").content rescue ta = ""
        tn = t.fetch_first_by_tag("n").content rescue tn = ""

        literature << ta + " " + tn
    end
    csv_line[:literature] = literature.join("\n")

    keywords = []
    source.marc.each_by_tag("650") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      keywords << ta
    end
    csv_line[:keywords] = keywords.join("\n")

    csv_line[:source_type] = ""
    t = source.marc.first_occurance("593")
    if t
      ta = t.fetch_first_by_tag("a").content rescue ta = ""
      csv_line[:source_type] = ta
    end

    csv_line[:date_to] = source.date_to
    csv_line[:date_from] = source.date_from

    material = []
    source.marc.each_by_tag("300") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      material << ta
    end
    csv_line[:material] = material.join("\n")

    plate = []
    source.marc.each_by_tag("0128") do |t|
      ta = t.fetch_first_by_tag("a").content rescue ta = ""

      plate << ta
    end
    csv_line[:plate] = plate.join("\n")

    return csv_line
end

headers = [:record_id, :signature, :copies, :in, :composer, :title, :standard_title, :literature, :keywords, :source_type, :date_to, :date_from, :material, :plate_no ]

CSV.open("data.csv", "wb", :headers => headers, :write_headers => true) do |csv|

    s = Source.where(record_type: 8).limit(100).each do |s|
        csv << marc2csv(s)
    end
end