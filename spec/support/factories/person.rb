FactoryBot.define do
  factory :person do
    full_name "Westmorland, John Fane of"
    life_dates "1784-1859"
    wf_stage 0
    wf_notes "BAWAHH :-)"
    marc_source <<STRING
=001  20000426
=024  7\#$a45033010$2VIAF
=024  7\#$a115445382$2DNB
=024  7\#$aQ5978904$2WKP
=040  #\#$aDE-633$bger$cDE-633
=100  1\#$aWestmorland, John Fane of$cLord Burghersh$d1784-1859
=400  1\#$aFane, John$d1784-1859
=400  1\#$aBurghersh, John Fane$d1784-1859
=400  1\#$aBurghersh, ...$d1784-1859
=400  1\#$aFane of Westmorland, John$d1784-1859
=400  1\#$aFane Burghersh, John$d1784-1859
=550  #\#$aSoldat$iprofession
=550  #\#$aGeneral$iprofession
=550  #\#$aKomponist$iprofession
=550  #\#$aDiplomat$iprofession
STRING
  end
  
  factory :person_bach, parent: :person do
    full_name "Bach, Johann Sebastian"
    marc_source <<STRING
=001  2539
=024  7\#$a12304462$2VIAF
=024  7\#$a11850553X$2DNB
=024  7\#$aQ1339$2WKP
=040  #\#$aDE-633
=042  #\#$aindividualized
=043  #\#$cXA-DE
=100  1\#$aBach, Johann Sebastian$d1685-1750$y21.03.1685-28.07.1750
=375  #\#$amale
=856  #\#$uhttp://www.oxfordmusiconline.com/subscriber/article/grove/music/40023pg10$yChristoph Wolff, et al. "Bach." Grove Music Online. Oxford Music Online. Oxford University Press. Web. 10 Aug. 2017
STRING
  end


end
