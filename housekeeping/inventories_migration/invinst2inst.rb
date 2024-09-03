das_map = {
"Zentral- und Hochschulbibliothek Luzern": 30000523,
"Dozza": 40003087,
"Bischöfliche Druckerei Konstanz": 51001834,
"Emmel, Egenolff": 40003306,
"Beuther, Georg": 40001027,
"Parcus, Leonhard": 40008210,
"Straub, Franz Xaver": 40010479,
"Faber, Albert Otto": 40003410,
"Müller, Henning": 40007745,
"Caesar, Johann Melchior": 40001838,
"Koppmayer, Jakob": 40005815,
"Sala, Giuseppe": 40009604,
"Halbmaier, Simon": 40004642,
"Wagenmann, Abraham": 30061366,
"Kirchner, Wolfgang": 40005705,
"Witte, Hans": 40011487,
"Eder, Wilhelm": 51003544,
"Enderlin, Jakob": 40003311,
"Vierdanck, Johann": 40011037,
"Jäger, Jakob": 40005493,
"Kreß, Johann Albrecht": 40005862,
"Trew, Paul": 40010826,
"Fueß, Joachim": 40008269,
"Corvinus, Georg": 40002591,
"Feyerabend, Sigmund": 40002591,
"Forckel, Johann": 40003600,
"Schneider, Zacharias": 51001956,
"Dehne, Johann Kaspar": 40002900,
"Mieth, Johann Christoph": 40007478,
"Stremel, Johann Heinrich": 40010488,
"Lau, Christoph Heinrich": 51005462,
"Hummel, Johann Julius": 40005292,
"Götze, Thomas Matthias": 51003460,
"Reyher, Salomon": 40008954,
"Schall, Johann Michael": 40009696,
"Mechel, Johann Konrad von": 40007337,
"Lorbeer, Melchior Gerhard": 40006866,
"Frommann, Georg Heinrich": 40003766,
"Kirchner, Christian": 40005699,
"Schnell, Johann Jakob": 40009819,
"Lang, Johann Baptist": 40006098,
"Schmid, Johann Michael": 40009777,
"Wagner, Christian Ulrich": 40011135,
"Klaffschenckel, Philipp Ludwig": 30075826,
"Mayer, Bernhard Homodeus": 51005227,
"Hagerer, Franciscus Salesius Ignatius": 40004630,
"Wagner, Johann Christoph": 40011140,
"Fischer, Johann Caspar Ferdinand": 40003542,
"Samm, Joseph": 30075903,
"Froberger, Christian Sigmund": 40003754,
"Monti, Pier Maria": 40007637,
"Vigone, Francesco": 40011042,
"Urban, Heinrich": 40010893,
"Diehl, Balthasar": 51006147,
"Sturm, August": 40010502,
"Lang, Johann Georg": 40006099,
"Le Clerc, Charles-Nicolas": 40006214,
"Carstens, Henrich": 40002020,
"Hänlin, Gregor": 40004595,
"Paur, Hans": 40000221,
"Custos, Dominicus": 40002739,
"Biber, Heinrich Ignaz Franz": 40001047,
"Gerlach, Theodor": 40004020,
"Hautt, Gottfried": 40004800,
"Komarek, Giovanni Giacomo": 51002667,
"Schröter, Johannes": 40009893,
"Dreher, Rudolph": 40003094,
"Straub, Franz": 40010479,
"Gäch, Johann": 40003804,
"Schönig, Johann Jakob": 40009846,
"Geng, Johann": 40003990,
"Friessem, Friedrich": 40003747,
"Hertz, Hiob": 40004939,
"Happach, Martin": 40009763,
"Bencard, Johann Caspar": 30061344,
"Kieffer, Karl": 40005688,
"Stein, Nicolaus": 40010392,
"Richter, Wolfgang": 40009039,
"Vollmar, Johann": 40011112,
"Dedekind, Friedrich Melchior": 40002896,
"Borboni, Nicolò": 40001379,
"Agricola, Daniel": 40000219,
"Carstens, Heinrich": 40002020,
"Straub, Leonhard": 40010480,
"Haenlin, Gregor": 40004595,
"Apiarius, Samuel": 40000397,
"Petri, Heinrich": 51000372,
"Curio, Hieronymus": 51007891,
"Hering, Michael": 51001169,
"Pfeiffer, Laurentius": 40008360,
"Kühn, Balthasar": 40005899,
"Neumayr, Adam": 40007990,
"Baudrexel, Philipp Jakob": 40000763,
"Galley, Johann Michael": 40003814,
"Straub, Lucas": 40010481,
"Plawenn, Leopold von": 40008494,
"Haffner, Johann Ulrich": 40004609,
"Reumann, Joachim": 40008929,
"Sengenwald, Georg": 40010007,
"Vaillant, Isaac": 40010905,
"Phalèse, Magdalène": 40008381,
"Bortoli, Camillo": 40001405,
"Robletti, Giovanni Battista": 40009125,
"Soldi, Luca Antonio": 40010260,
"Rolla, Carlo Francesco": 40009176,
"Lazzari, Pelegrino": 40006174,
"Mutij, Giovanni Angelo": 40007828,
"Young, John": 40011609,
"Dorico, Valerio & Lodovico fratelli": 40003081,
"Rosati, Fortuniano": 40009198,
}

array = CSV.read('housekeeping/inventories_migration/inventory_institutions-csv.csv', headers: true).map(&:to_h)

id_map = {}
count = 0
array.each do |i| 
    sanit_name = i["name"].gsub("[A/I]", "").strip

    pers =  Institution.where(name: sanit_name)
    
    if !pers[0]
        pers2 = Institution.where(id: das_map[sanit_name.to_sym])
        pers = pers2
    end

    #return[i["ext_id"], pers[0].id]
    if !pers[0]

        res = Institution.solr_search do
            adjust_solr_params do |p|
                p["q.op"] = "AND"
              end
            #fulltext sanit_name, :fields => [:full_name,  :"400a"]
            #fulltext sanit_name, :fields => :"400a"
            #with "full_name_or_400a", sanit_name
            fulltext sanit_name
        end

        #puts sanit_name

        #ap res.results.count
        #ap res.results if sanit_name == "Saint Lambert, de"
        #print "#{sanit_name} | "
        #res.results.each do |r|
            #print "#{r.full_name} #{r.life_dates} | "
        #end

        #if res.results.count > 1
        #    puts sanit_name.red
        #    res.results.each do |r|
        #        puts "-> #{r.full_name} #{r.id},"
        #        puts "\"#{sanit_name}\": #{r.id},"
        #    end
        #    puts
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