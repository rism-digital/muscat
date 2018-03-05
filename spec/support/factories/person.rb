FactoryBot.define do
  factory :person do
    id 2539
    full_name "Bach, Johann Sebastian"
    initialize_with { Person.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    #initialize_with { Person.find_or_create_by(id: id)  } 
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



