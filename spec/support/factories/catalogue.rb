FactoryBot.define do
  factory :catalogue do
    id 	 1536
    name 	 "NBA"
    initialize_with { Catalogue.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    description 	 "Johann Sebastian Bach: Neue Ausgabe sämtlicher Werke"
    revue_title 	 ""
    volume 	 nil
    place 	 "Kassel, Basel"
    date 	 "1954-"
    pages 	 nil
    wf_audit 	 "full"
    wf_stage 	 "published"
    people { [association(:person)]  }
    #referring_sources { [association(:source)]  }
    wf_notes 	 nil
    marc_source <<STRING
=001  1536
=041  0\#$ager
=210  #\#$aNBA
=240  10$aJohann Sebastian Bach: Neue Ausgabe sämtlicher Werke$gMusic edition$hMonograph
=260  #\#$aKassel, Basel$c1954-
=337  #\#$aPrinted music
=500  #\#$aser.X, vol.X, p.X
=500  #\#$aser.X, vol.X (Kritischer Bericht), p.X
=500  #\#$aser.1, vol.23, p.161
=500  #\#$aser.2, vol.5 (Kritischer Bericht), p.94-96
=700  1\#$aBach, Johann Sebastian$d1685-1750$02539$4cmp
STRING
  end
 end
