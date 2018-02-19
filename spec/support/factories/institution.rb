FactoryBot.define do
  factory :institution do
    id           30000655
    siglum       "D-B"
    initialize_with { Institution.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    #initialize_with { Institution.find_or_create_by(id: id)  } 
    name         "Staatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung"
    address      "Staatsbibliothek zu Berlin - Preußischer,  Kulturbesitz, Musikabteilung, Unter den Linden 8, 10117 Berlin, Germany"
    url          "http://staatsbiblioth..."
    phone        nil
    email        nil
    wf_audit     "full"
    wf_stage     "published"
    wf_notes     nil
    wf_owner     1
    place        "Berlin"
    places { [association(:place)] }
    marc_source "=001  30000655\r\n=024  #\#$a2116114-8$2DNB\r\n=024  #\#$aDE-1$2ISIL\r\n=034  2\#$d13.39099$f52.51752\r\n=040  #\#$aDE-633\r\n=043  #\#$cXA-DE\r\n=110  2\#$aStaatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung$cBerlin$gD-B\r\n=368  #\#$aB; K\r\n=371  #\#$aStaatsbibliothek zu Berlin - Preußischer,  Kulturbesitz, Musikabteilung, Unter den Linden 8, 10117 Berlin, Germany$uhttp://staatsbibliothek-berlin.de/\r\n=410  2\#$aStiftung Preußischer Kulturbesitz\r\n=551  #\#$aBerlin$03900054\r\n"
  end
  
  factory :foreign_institution, parent: :institution do
    id           30001488 
    siglum       "F-Pn"
    initialize_with { Institution.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    marc_source <<STRING
=001  30001488
=024  #\#$a2116114-8$2DNB
=024  #\#$aDE-1$2ISIL
=034  2\#$d13.39099$f52.51752
=040  #\#$aDE-633
=043  #\#$cXA-FR
=110  2\#$aBibliotheque nationale$cParis$gF-Pn
=368  #\#$aB; K
=371  #\#$aBibliotheque nationale$uhttp://fnac.fr
=410  2\#$aBNF
STRING
  end

end
