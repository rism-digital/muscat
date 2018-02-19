FactoryBot.define do
  factory :work do
    title "Bach, Johann Sebastian: Was Gott tut, das ist wohlgetan BWV 98 ; "
    wf_stage "published"
    person { FactoryBot.create(:person) }
    #people { [association(:bach)]  }
    marc_source <<STRING
=001  3
=024  7\#$a183554358$2VIAF
=024  7\#$a300007906$2DNB
=040  #\#$aDE-633$bger$cDE-633
=100  1\#$aBach, Johann Sebastian$d1685-1750$nBWV 98$tWas Gott tut, das ist wohlgetan$02539
STRING
  end
end

