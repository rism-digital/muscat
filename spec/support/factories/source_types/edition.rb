FactoryBot.define do
  factory :edition, :parent => :source do
    id 111
    record_type 8
    std_title "Variations - cemb"
    composer "Bach, Johann Sebastian"
    title "Goldberg"
    shelf_mark ""
    language "Unknown"
    wf_stage "published"
    people { [association(:person)]  }
    holdings { [association(:holding)]  }
    standard_titles { [association(:standard_title)]  }
    standard_terms { [association(:standard_term)]  }
    initialize_with { Source.where(id: id).where.not(marc_source: nil).first_or_initialize(attributes) }
    marc_source <<STRING
=040  #\#$aDE-633
=100  1\#$aBach, Johann Sebastian$d1685-1750$02539
=240  10$aJesu meine Freude$nBC C 5$03905618
=245  10$aGoldberg
=593  #\#$aPrint$801
=650  00$aMotets$025240
STRING
 end  
end
 
