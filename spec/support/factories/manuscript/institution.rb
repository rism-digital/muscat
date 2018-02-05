FactoryBot.define do
  factory :manuscript_institution, parent: :institution do
    id           30000655
    siglum       "D-B"
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
    places { [association(:manuscript_place)] }
    marc_source "=001  30000655\r\n=024  #\#$a2116114-8$2DNB\r\n=024  #\#$aDE-1$2ISIL\r\n=034  2\#$d13.39099$f52.51752\r\n=040  #\#$aDE-633\r\n=043  #\#$cXA-DE\r\n=110  2\#$aStaatsbibliothek zu Berlin - Preußischer Kulturbesitz, Musikabteilung$cBerlin$gD-B\r\n=368  #\#$aB; K\r\n=371  #\#$aStaatsbibliothek zu Berlin - Preußischer,  Kulturbesitz, Musikabteilung, Unter den Linden 8, 10117 Berlin, Germany$uhttp://staatsbibliothek-berlin.de/\r\n=410  2\#$aStiftung Preußischer Kulturbesitz\r\n=551  #\#$aBerlin$03900054\r\n"
  end





end
