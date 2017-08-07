FactoryGirl.define do
  factory :person do
    full_name "Westmorland, John Fane of"
    life_dates "1784-1859"
    wf_stage 1
    marc_source <<STRING
=001  91008161
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
end
