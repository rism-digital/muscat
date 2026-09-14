require_relative 'legacy_file.rb'

data =<<~DATA
51043284	Willaert, Adrian
51043283	Cecchino, Tommaso
51043282	Leoni, Leone
51043281	Marastoni, Antonio
51043280	La Greca, Antonio
51043279	Bonfiglio, Corrado
51043278	Francesco da Taranto
51043277	Rinaldi, Andrea
51043276	Di Laurenzo, Mariano
51043275	D'Elia, Vincenzo
51043274	Savetta, Antonio
51043273	Rubino, Bonaventura
51043272	Ortiz de Zarate, Cristoforo
51043271	Conticino, Paolo
51043270	Dell'Arpi, Francesco
51043269	Deodato, Corrado
51043268	Fortunio, Giacinto Maria
51043267	Venezia, Vincenzo
51043266	Licari, Antonio
51043265	Cardona, Michele
51043264	Pellegrini, Salvatore
51043263	Galeano, Ignazio
51043262	Mendoza Sandoval y Roxas, Rodrigo
51043261	Graziani, Bonifacio
51043260	Colombini, Francesco
51043259	Cattaneo, Bernardino
51043258	Giudici, Giovanni Battista
51043257	Farnese, Ottavio
51043256	Varotto (Varotus), Michele
51043255	Rambelli, Giovanni
51043254	Casati, Girolamo
51043253	Asola, Giovanni Matteo
51043252	Morales, Cristobal
51043251	Cantone, Serafino
51043250	Croce, Giovanni
DATA

legacy = LegacyFile.new("housekeeping/psmd/psmd.yml")

more_map = {}

CSV.parse(data, col_sep: "\t", headers: %i[id name]).each do |r|
    mus = Person.where(full_name: r[:name])

    l = legacy.find_by(:people, :full_name, r[:name])

    if mus.count > 1
        ## do somethijg clever
        puts legacy.find_by(:people, :full_name, r[:name])
        ap mus.map(&:full_name)
    elsif mus.count == 0
        puts "NO MUSCAT #{l["ext_id"]} #{l["full_name"]}"

    else
        more_map[l["ext_id"].to_s] = mus.first.id
    end
end

ap more_map