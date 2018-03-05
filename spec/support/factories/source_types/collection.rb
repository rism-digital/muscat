FactoryBot.define do 
  factory :collection, :parent => :source do
    id 51649
    source_id  nil
    record_type  1
    title  "[spine:] ARIAS | G. ABOS | FIORAVANTI | GALUPPI | GLUCK | GRETRY"
    shelf_mark "M.120.16 (1-9)"
    lib_siglum "D-B"
    initialize_with { Source.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    marc_source <<STRING
=001  000051649
=240  10$aJesu meine Freude$nBC C 5$03905618
=245  10$a[spine:] ARIAS | G. ABOS | FIORAVANTI | GALUPPI | GLUCK | GRETRY
=260  #\#$c1790-1810 (18/19)$801
=300  #\#$ascore: 142f.$801
=500  #\#$aCataloguer's note, f.2v: \"xxM120.16 | Allen A Brown | 10. June, 1898\"
=520  #\#$aRecitatives, arias and duetti from different operas
=590  #\#$aS and b$b8f.$801
=593  #\#$aManuscript copy$801
=594  #\#$bV$cX
=852  #\#$aD-B$cMus.ms.Bach P 48, Faszikel 7$eStaatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung$x30000655
STRING

  end


end
