@mc = MarcConfigCache.get_configuration("person")

#@mods = []

#: {short_name: "", author: "", title: ""}
CMO_LIT = {
    "cmo_mods_00000008": {short_name: "TMA", author: "Öztuna, Yılmaz", title: "Türk Mûsikîsi Ansiklopedisi"},
    "cmo_mods_00000009": {short_name: "TMAS", author: "Nezihi Turan, Ahmet", title: "Türk mûsikîsi akademik klasik Türk san'at mûsikîsi'nin ansiklopedik sözlüğü"},
    "cmo_mods_00000010": {short_name: "LVE", author: "Ḥāfıẓ Ḫıżır İlyās", title: "Leṭāʾif-i veḳāʾi-yi enderūnīye"},
    "cmo_mods_00000011": {short_name: "Hiwrmiwzean 1873", author: "Hiwrmiwzean, Eduard", title: "Tirac‘u Hambarjum"},
    "cmo_mods_00000012": {short_name: "Mert 2011", author: "Mert, Talip", title: "Mehmed Şâkir Efendi/Şâkir Ağa: Sermüezzin, Kereste Nâzırı ve Su Nâzırı (1779–31.3.1837)"},
    "cmo_mods_00000014": {short_name: "MMA", author: "Sözer, Vural", title: "Müzik ve Müzisyenler Ansiklopedisi"},
    "cmo_mods_00000016": {short_name: "Reinhard/Pinto 1989", author: "Reinhard, Ursula; Oliveira Pinto, Tiago de", title: "Sänger und Poeten mit der Laute : Türkische Âşık und Ozan"},
    "cmo_mods_00000021": {short_name: "MA", author: "Say, Ahmet", title: "Müzik Ansiklopedisi"},
    "cmo_mods_00000022": {short_name: "TRTS", author: "Kip, Tarık", title: "TRT Türk Sanat Musikisi Saz Eserleri Repertuvarı: Ön basım"},
    "cmo_mods_00000024": {short_name: "Feldman 1996", author: "Feldman, Walter", title: "Music of the Ottoman Court : Makam, Composition and the Early Ottoman Instrumental Repertoire"},
    "cmo_mods_00000025": {short_name: "MA2", author: "Say, Ahmet", title: "Müzik Ansiklopedisi : Besteciler, Yorumcular, Eserler, Kavramlar"},
    "cmo_mods_00000026": {short_name: "Toker 2016", author: "Toker, Hikmet", title: "Elhân-ı Aziz : Sultan Abdülaziz Devrinde Sarayda Mûsik"},
    "cmo_mods_00000030": {short_name: "Mēnēvišean 1890", author: "Mēnēvišean, H. Gabriēl", title: "Azgabanut‘iwn aznowakan zarmin Tiwzeanc‘"},
    "cmo_mods_00000031": {short_name: "Yazıcı 2011", author: "Yazıcı, Ümit", title: "Tanbûri Ali Efendi : Hayatı ve Eserleri"},
    "cmo_mods_00000032": {short_name: "Kalaitzidis 2012", author: "Kalaitzidis, Kyriakos", title: "Post-Byzantine Music Manuscripts as a Source for Oriental Secular Music (15th to Early 19th Century)"},
    "cmo_mods_00000035": {short_name: "Uzunçarşılı 1977", author: "Uzunçarşılı, İsmail Hakkı", title: "Osmanlılar Zamanında Saraylarda Musiki Hayatı"},
    "cmo_mods_00000036": {short_name: "Tayean 1930", author: "Tayean, Łewond", title: "Mayr Diwan: Mxit‘areanc‘ Venetkoy i S. Łazar, 1707–1773 : I cagmanē uxtis minč‘ew c‘bažanumn t‘restean harc‘"},
    "cmo_mods_00000037": {short_name: "Neubauer 1997", author: "Neubauer, Eckhard", title: "Zur Bedeutung der Begriffe Komponist und Komposition in der Musikgeschichte der islamischen Welt"},
    "cmo_mods_00000040": {short_name: "Korkmaz 2015", author: "Korkmaz, Harun", title: "The Catalog of Music Manuscripts in Istanbul University Library"},
    "cmo_mods_00000042": {short_name: "Mert 1999", author: "Mert, Talip", title: "Ortaçağ’ın en büyük kadın bestekârı: Dilhayat Kalfa’nın Mirası:"},
    "cmo_mods_00000044": {short_name: "Cemil, Mes’ud", author: "Cemil, Mes’ud", title: "Tanbūrî Cemil’in Hayâtı"},
    "cmo_mods_00000045": {short_name: "İA2", author: "Türkiye Diyanet Vakfı", title: "Türkiye Diyanet Vakfı İslâm Ansiklopedisi"},
}

@defined_lit = {}

def preprocess_cmo(marc, obj, options)
    #puts "Callback to process #{obj.id}"

    cmo_id = marc.first_occurance("001").content
    
    # Remove the old 001
    marc.by_tags("001").each {|t2| t2.destroy_yourself}

    # And make a new one
    # Add it in position 1 since there is a 000 in the original data
    marc.root.add_at(MarcNode.new("person", "001", "__TEMP__", nil), 1)

    n024 = MarcNode.new("person", "024", "", @mc.get_default_indicator("024"))
   
    n024.add_at(MarcNode.new("person", "a", cmo_id, nil), 0 )
    n024.add_at(MarcNode.new("person", "2", "CMO", nil), 0 )
    n024.sort_alphabetically
    marc.root.add_at(n024, marc.get_insert_position("024") )

    n040 = MarcNode.new("person", "040", "", @mc.get_default_indicator("040"))
    n040.add_at(MarcNode.new("person", "a", "DE-4353", nil), 0 )
    n040.add_at(MarcNode.new("person", "b", "eng", nil), 0 )
    n040.add_at(MarcNode.new("person", "c", "DE-633", nil), 0 )
    n040.sort_alphabetically
    marc.root.add_at(n040, marc.get_insert_position("040") )

    # We moved this to 024
    marc.by_tags("100").each do |t|
        t.fetch_all_by_tag("0").each {|tt| tt.destroy_yourself}
    end

    marc.by_tags("678").each do |t|
        # is there a $b and no $a? Then it is a name!
        a = t.fetch_first_by_tag("a")
        b = t.fetch_first_by_tag("b")
        if (b && b.content) && !a
            ## Move it to an  note
            n680 = MarcNode.new("person", "680", "", @mc.get_default_indicator("680"))
            n680.add_at(MarcNode.new("person", "a", b.content, nil), 0 )
            n680.sort_alphabetically
            marc.root.add_at(n680, marc.get_insert_position("680") )
            puts "Moved date to 680"
        end

        # We have stuff in $w too
        w = t.fetch_first_by_tag("w")
        b = t.fetch_first_by_tag("b")

        # This field can also contain bib info!
        # see cmo_person_00000497
        if a && a.content && !a.content.empty?
            # There is bib data to move
            # Do some magics
            parts = a.content.split(", ")

            # Remove the unwanted spaces...
            sanitized = parts[0].split.join(" ")

            n670 = MarcNode.new("person", "670", "", @mc.get_default_indicator("670"))

            n670.add_at(MarcNode.new("person", "a", sanitized, nil), 0 ) # Add the revue name
            n670.add_at(MarcNode.new("person", "9", parts[1], nil), 0 )if parts[1]  # add the pages

            # Move the other things
            n670.add_at(MarcNode.new("person", "b", b&.content, nil), 0 ) if b && b.content
            n670.add_at(MarcNode.new("person", "u", w&.content, nil), 0 ) if w && w.content

            #@mods << w&.content

            n670.sort_alphabetically
            marc.root.add_at(n670, marc.get_insert_position("670") )
        end

    end

    # Purge all the 678
    marc.by_tags("678").each {|t| t.destroy_yourself}

    marc.by_tags("024").each do |t|
        a = t.fetch_first_by_tag("a")

        if !a || !a.content || a.content.empty?
            puts "Remove empty #{t}"
            t.destroy_yourself
        end
    end

    marc.by_tags("400").each do |t|
        a = t.fetch_first_by_tag("a")
        w = t.fetch_first_by_tag("w")

        if w && w.content
            # Move to internal note
            n667 = MarcNode.new("person", "667", "", @mc.get_default_indicator("667"))
            n667.add_at(MarcNode.new("person", "a", "#{a&.content} | #{w.content}", nil), 0 )
            n667.sort_alphabetically
            marc.root.add_at(n667, marc.get_insert_position("667") )
        end

        # Remove it
        t.fetch_all_by_tag("w").each {|tt| tt.destroy_yourself}
    end

    # move 1 to u
    marc.by_tags("910").each do |t|
        t.fetch_all_by_tag("1").each {|tt| tt.tag = "u"}
    end

    return marc
end

def create_cmo_lit

    mconf = MarcConfigCache.get_configuration("publication")

    #new_marc = MarcPublication.new(File.read(ConfigFilePath.get_marc_editor_profile_path("#{Rails.root}/config/marc/#{RISM::MARC}/publication/default.marc")))
    #new_marc.load_source false # this will need to be fixed
    
    CMO_LIT.each do |name, vals|
        item = Publication.new(author: vals[:author], short_name: vals[:short_name], title: vals[:title])
        item.save!

        item.marc.by_tags("100").each {|t| t.destroy_yourself}

        new_100 = MarcNode.new("publication", "100", "", mconf.get_default_indicator("100"))
        new_100.add_at(MarcNode.new("publication", "a", vals[:author], nil), 0)

        n856 = MarcNode.new("publication", "856", "", "1#")
        new_100.add_at(MarcNode.new("publication", "a", vals[:author], nil), 0)

        item.marc.root.children.insert(item.marc.get_insert_position("100"), new_100)
        item.marc.import
        item.save

    end
end

DIR="cmo_person_marcxml_20241213"
#CMO-MARCXML/Person/

files = Dir.glob("#{DIR}/*.xml")

#source_file = "CMO-MARCXML/Person/cmo_person_00000001.xml"

# Minimal option set
options = {first: 0, last: 1000000, versioning: false, index: true}

options[:new_ids] = true
options[:authorities] = true
options[:callback] = method(:preprocess_cmo)

$MARC_DEBUG=true
$MARC_LOG=[]
$MARC_FORCE_CREATION = false

complete_log = []

create_cmo_lit
CULO

files.each do |source_file|
    puts source_file
    import = MarcImport.new(source_file, "Person", options)
    import.import

    $MARC_LOG.each do |l|
        next if l[0] == "MARC"
        complete_log << l.join("\t")
    end
    $MARC_LOG = []
end
Sunspot.commit
complete_log.sort.uniq.each {|l| puts l}

ap @mods.sort.uniq