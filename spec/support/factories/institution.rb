FactoryBot.define do
  factory :institution do
    id 30001581
    siglum "GB-Lxxx"
    marc_source <<STRING
=034  2\#$d-0.1266$f51.52903
=040  #\#$aDE-633
=043  #\#$cXA-GB
=110  2\#$aThe British XLibrary$cLondon$gGB-Lxxx
=368  #\#$aB; K
=371  #\#$aThe British XLibrary, St Pancras, 96 Euston Road, London NW1 2DB, United Kingdom$uhttp://www.bl.uk/
=551  #\#$aLondon$03900003
STRING
  
    trait :foreign do
      siglum "F-Pxxx"
      marc_source <<STRING
=034  2\#$d-0.1266$f51.52903
=040  #\#$aDE-633
=043  #\#$cXA-FR
=110  2\#$aThe British XLibrary$cLondon$gF-Pxxx
=368  #\#$aB; K
=371  #\#$aNowhere$uhttp://www.bl.uk/
=551  #\#$aLondon$03900003
STRING
    end

    factory :foreign_institution, :traits => [:foreign]

  end

end
