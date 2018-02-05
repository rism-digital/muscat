FactoryBot.define do
  factory :manuscript_catalogue, parent: :catalogue do
    id 	 1536
    name 	 "NBA"
    description 	 "Johann Sebastian Bach: Neue Ausgabe sämtlicher Werke"
    revue_title 	 ""
    volume 	 nil
    place 	 "Kassel, Basel"
    date 	 "1954-"
    pages 	 nil
    wf_audit 	 "full"
    wf_stage 	 "published"
    wf_notes 	 nil
    marc_source 	 "=001  1536\r\n=041  0\#$ager\r\n=210  #\#$aNBA\r\n=240  10$aJohann Sebastian Bach: Neue Ausgabe sämtlicher Werke$gMusic edition$hMonograph\r\n=260  #\#$aKassel, Basel$c1954-\r\n=337  #\#$aPrinted music\r\n=500  #\#$aser.X, vol.X, p.X\r\n=500  #\#$aser.X, vol.X (Kritischer Bericht), p.X\r\n=500  #\#$aser.1, vol.23, p.161\r\n=500  #\#$aser.2, vol.5 (Kritischer Bericht), p.94-96\r\n=700  1\#$aBach, Johann Sebastian$d1685-1750$02539$4cmp\r\n"
  end
  
  trait :catalogue_wv do
    id 	 11
    name 	 "BWV"
    author 	 "Schmieder, Wolfgang"
    description 	 "Thematisch-systematisches Verzeichnis der musikalischen Werke von Johann Sebastian Bach. Bach-Werke-Verzeichnis: 2., überarbeitete und erweiterte Auflage"
    revue_title 	 ""
    volume 	 nil
    place 	 "Wiesbaden"
    date 	 "1990"
    pages 	 nil
    wf_audit 	 "full"
    wf_stage 	 "published"
    marc_source 	 "=001  11\r\n=041  1\#$ager\r\n=100  1\#$aSchmieder, Wolfgang$d1901-1990$080134$4aut\r\n=210  10$aBWV\r\n=240  10$aThematisch-systematisches Verzeichnis der musikalischen Werke von Johann Sebastian Bach. Bach-Werke-Verzeichnis: 2., überarbeitete und erweiterte Auflage$gWork catalog$hbook\r\n=260  #\#$aWiesbaden$bBreitkopf & Härtel [Wiesbaden]$c1990\r\n=300  1\#$aXLVI, 1014p.\r\n=337  1\#$aPrinted medium\r\n=500  1\#$aDie neue Auflage hat neue Zitierweisen, z.B.: 1006a/1000 (=Suite E-Dur, vormals BWV-Nr. 1006a, steht jetzt hinter der Nr. 1000)\r\n=500  1\#$aBrookCM 1997: 62\r\n=500  1\#$aSigel. Verzeichnis-Nr\r\n=500  1\#$aSigel. Anh.X:Nummer\r\n=500  1\#$aBWV. 38 (Kantate \"Aus tiefer Not schrei ich zu dir\")\r\n=500  1\#$aBWV. Anh.2:80 (Suite F-Dur, zweifelhaft)\r\n=500  1\#$aBWV. 142/Anh.2:23 (Kantate \"Uns ist ein Kind geboren\"\r\n=500  1\#$azweifelhaft)\r\n=599  1\#$aRISM-HB\r\n=700  1\#$aBach, Johann Sebastian$d1685-1750$02539$4cmp\r\n"
  end

  factory :manuscript_catalogue_wv, :traits => [:catalogue_wv]

end
