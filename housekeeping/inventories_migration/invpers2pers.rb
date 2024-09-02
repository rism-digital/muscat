das_map = {
"Hagerer, Franziscus Salesius Ignatius": 30006855,
"Michna, Adam Vàclav": 30009543,
"San Romano, Carlo Giuseppe": 30010106,
"Rosier, Carl Natalis": 30010257,
"Vannini, Fra Elia": 30010781,
"Scipione, Giovanni": 30011252,
"Albicastro, Henricus": 30011715,
"Demantius, Johannes Christoph": 30012075,
"Cocx, Joannes": 30012145,
"Regnard, Jean François": 30032289,
"Geisenhof, Johannes": 30012340,
"Simon, Johann Kaspar": 344629,
"Spiess, Johann Martin": 30012583,
"Paix, Jacob": 30012685,
"Macarani, Stefano": 30015961,
"Rossi, Christoforo Sforza": 30016037,
"Hardmeyer, Johann Caspar": 30016169,
"Biber, Heinrich Ignaz Franz": 20000428,
"Capricornus, Samuel Friedrich": 30000576,
"Cavalli, Pier Francesco": 30000620,
"Grancino, Michelangelo": 30001343,
"Holzbauer, Ignaz Jakob": 30001549,
"Schickhard, Johann Christian": 30002875,
"Schlecht, Franz Xaver": 30002878,
"Schreiber, Johannes Evangelista": 30002920,
"Lichtenauer, Paul Ignaz": 30005179,
"Münster, Joseph Joachim": 30005226,
"Rossi, Salomone": 30005265,
"Schadaeus, Abraham": 30050295,
"Donfrid, Johann": 30057934,
"Frisoni, Lorenzo": 41023556,
"Listenius, Nikolaus": 51017678,
"Grieninger, Paul": 30009430,
"Agricola, Johannes Paul": 30092350,
"Hegner, Jacob": 30109961,
"Huber, Christian": 30030789,
"Wagner, Samuel": 30085002,
"Buns, Benedictus": 30005624,
"Duenas": 30028992,
"Argentini, Stefano": 30014215,
"Serperio, Francesco": 50051014,
"Schenk, Johannes": 30002867,
"Masson, Charles": 30102353,
}

array = CSV.read('inventory_names-csv.csv', headers: true).map(&:to_h)

id_map = {}

array.each do |i| 
    sanit_name = i["full_name"].gsub("[A/I]", "").strip

    pers =  Person.where(full_name: sanit_name)

    #sanit_name = "Hagerer" if sanit_name == "Hagerer, Franziscus Salesius Ignatius"
    #ap sanit_name.to_sym
    #ap das_map[sanit_name.to_sym]
    
    if !pers[0]
        pers2 = Person.where(id: das_map[sanit_name.to_sym])
        pers = pers2
    end

    #return[i["ext_id"], pers[0].id]
    if !pers[0]

        res = Person.solr_search do
            adjust_solr_params do |p|
                p["q.op"] = "AND"
              end
            fulltext sanit_name, :fields => [:full_name,  :"400a"]
            #fulltext sanit_name, :fields => :"400a"
            #with "full_name_or_400a", sanit_name
        end

        #ap res.results.count
        #ap res.results if sanit_name == "Saint Lambert, de"
        #print "#{sanit_name} | "
        #res.results.each do |r|
            #print "#{r.full_name} #{r.life_dates} | "
        #end

        #f res.results.count > 1
        #    puts sanit_name.red
        #    res.results.each do |r|
        #        puts "-> #{r.full_name} #{r.id},"
        #        puts "\"#{sanit_name}\": #{r.id},"
        #    end
        #end

        #
        #if res.results.count == 1
        #    puts "\"#{sanit_name}\": #{res.results.first.id},"
        #end

        #puts sanit_name if res.results.count == 0

        #next

    end

    #ap pers[0].id
    id_map[i["ext_id"]] = pers[0].id if pers[0]
end

puts id_map.to_yaml

#webapp=/solr path=/select params={q=Saint+Lambert,+de&defType=edismax&qf=full_name_text+400a_text&fl=*+score&start=0&fq=type:Person&rows=30&wt=json} hits=5416 status=0 QTime=0
#webapp=/solr path=/select params={q=Saint+Lambert,+de&defType=edismax&qf=full_name_text+400a_text&fl=*+score&start=0&q.op=AND&fq=type:Person&sort=id_i+desc&rows=30&wt=json} hits=2 status=0 QTime=0