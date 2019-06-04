FactoryBot.define do
  
  factory :manuscript_source, parent: :source do
    id { 989000434 }
    source_id         { nil }
    record_type       { 2 }
    #nitialize_with { Source.find_or_create_by(id: id) } 
    initialize_with { Source.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    std_title         { "Jesu meine Freude - BWV 227" }
    std_title_d       { "jesu meine freude - bwv 227" }
    composer          { "Bach, Johann Sebastian" }
    composer_d        { "bach, johann sebastian" }
    title             { "[unset]" }
    title_d           { "[unset]" }
    shelf_mark        { "Mus.ms.Bach P 48, Faszikel 7" }
    language          { "Unknown" }
    date_from         { nil }
    date_to           { nil }
    lib_siglum       { "D-B" }
    wf_owner          { 2 }
    wf_stage          { "published" }
    wf_audit         { "full" }
    people { [association(:person)]  }
    institutions { [association(:institution)]  }
    standard_titles { [association(:standard_title)]  }
    standard_terms { [association(:standard_term)]  }
    created_at { Time.now }
    #catalogues { [association(:catalogue)]  }
    #sources []
    #places { [association(:manuscript_place)] }
    marc_source {  <<STRING
=001  989000434
=035  #\#$aB00900000
=100  1\#$aBach, Johann Sebastian$d1685-1750$02539
=240  10$aJesu meine Freude$nBC C 5$03905618
=245  10$aJesu meine Freude
=300  #\#$ascore: 10f.$c34 x 21,5 cm$801
=500  #\#$aSchreiber: unbekannter Schreiber (J. F. Hering?)
=500  #\#$aVorlage: verschollene Partitur
=500  #\#$aLiteratur: Faulstich, Nr. 425, Nr. 466; P. Wollny, in: SIM-Jb. 1995, S. 80-113
=500  #\#$aBemerkung: Wahrscheinlich identisch mit verschollen BWV 227 (6)
=541  #\#$a? - J. Christian Westphal - Voß-Buch (1830) - BB (jetzt Staatsbibliothek zu Berlin Preußischer Kulturbesitz) (1851)
=592  #\#$aa) W in überkröntem Schild - b) leer (oder nicht erkennbar)$801
=599  #\#$aUrsprüngliche Namensansetzung: J. Franck [Berlin 1653]
=650  00$aMotets$025240
=852  #\#$aD-B$cMus.ms.Bach P 48, Faszikel 7$eStaatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung$x30000655
=856  40$uhttp://www.bach-digital.de/receive/BachDigitalSource_source_00000900$zBach Digital
STRING
    }
  end
  
  factory :foreign_manuscript_source, parent: :source do
    id { 989000434 }
    source_id         { nil }
    record_type       { 2 }
    #nitialize_with { Source.find_or_create_by(id: id) } 
    initialize_with { Source.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    std_title         { "Jesu meine Freude - BWV 227" }
    std_title_d       { "jesu meine freude - bwv 227"}
    composer          { "Bach, Johann Sebastian"} 
    composer_d        { "bach, johann sebastian"}
    title             { "[unset]"}
    title_d           { "[unset]"}
    shelf_mark        { "Mus.ms.Bach P 48, Faszikel 7"}
    language          { "Unknown"}
    date_from         { nil}
    date_to           { nil}
    lib_siglum       { "F-Pn"}
    wf_owner          { 2}
    wf_audit         { "full"}
    people { [association(:person)]  }
    institutions { [association(:foreign_institution)]  }
    standard_titles { [association(:standard_title)]  }
    standard_terms { [association(:standard_term)]  }
    created_at { Time.now }
    #catalogues { [association(:catalogue)]  }
    #sources []
    #places { [association(:manuscript_place)] }
    marc_source {  <<STRING
=001  989000434
=035  #\#$aB00900000
=100  1\#$aBach, Johann Sebastian$d1685-1750$02539
=240  10$aJesu meine Freude$nBC C 5$03905618
=245  10$aJesu meine Freude
=300  #\#$ascore: 10f.$c34 x 21,5 cm$801
=500  #\#$aSchreiber: unbekannter Schreiber (J. F. Hering?)
=500  #\#$aVorlage: verschollene Partitur
=500  #\#$aLiteratur: Faulstich, Nr. 425, Nr. 466; P. Wollny, in: SIM-Jb. 1995, S. 80-113
=500  #\#$aBemerkung: Wahrscheinlich identisch mit verschollen BWV 227 (6)
=541  #\#$a? - J. Christian Westphal - Voß-Buch (1830) - BB (jetzt Staatsbibliothek zu Berlin Preußischer Kulturbesitz) (1851)
=592  #\#$aa) W in überkröntem Schild - b) leer (oder nicht erkennbar)$801
=599  #\#$aUrsprüngliche Namensansetzung: J. Franck [Berlin 1653]
=650  00$aMotets$025240
=852  #\#$aF-Pn$cMs 100$eBibliothèque nationale de France$x30001488
=856  40$uhttp://www.bach-digital.de/receive/BachDigitalSource_source_00000900$zBach Digital
STRING
  }
  end

end
 
