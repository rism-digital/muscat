require_relative 'legacy_file.rb'

data =<<~DATA
51009802	Arnazzini, Gregorio
51009801	eredi del Zannetti
51009800	Camagni, Giovanni Francesco e fratelli
51009799	de Lazari, Ignazio
51009798	il Venetiano
51009797	Mascardi, Vitale
51009796	Fei d'Andrea, Giacomo
51009795	Belmonte, Amadeo
51009794	Pontio, Paolo Gottardo
51009793	Gardano, Antonio
51009792	s. n.
51009791	Tini, Francesco e eredi di Simon
51009790	Monti, Giacomo
51009789	Amadino, Ricciardo
51009788	Cancer, Mattias
51009787	Scotto, Girolamo
51009786	Lomazzo, Filippo
51009785	Camagno
51009784	Tradate, Agostino
51009783	Simonetti, Leonardo
51009782	Robletti, Giovanni Battista
51009781	Vincenti, Giacomo
51009780	Rolla, Giorgio
51009779	Magni, Bartolomeo
DATA

legacy = LegacyFile.new("housekeeping/psmd/psmd.yml")

more_map = {}

CSV.parse(data, col_sep: "\t", headers: %i[id name]).each do |r|
    mus = Institution.where(full_name: r[:name])

    l = legacy.find_by(:institutions, :name, r[:name])

    if mus.count > 1
        ## do somethijg clever
        puts legacy.find_by(:institutions, :name, r[:name])
        ap mus.map(&:full_name)
    elsif mus.count == 0
        puts "NO MUSCAT #{l["ext_id"]} #{l["full_name"]}"

    else
        more_map[l["ext_id"].to_s] = mus.first.id
    end
end

ap more_map