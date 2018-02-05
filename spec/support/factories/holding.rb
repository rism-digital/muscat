FactoryBot.define do
  factory :holding do
    lib_siglum "GB-xxx"
    wf_stage "published"
    institutions { [association(:institution)]  }
  end
  
  factory :holding_fr, :parent => :holding do
    lib_siglum "F-Pn"
    wf_stage "published"
    institutions { [association(:foreign_institution)]  }
    marc_source <<STRING
=852  #\#$aF-Pn$cMs 100$eBibliothèque nationale de France$x30001488
STRING
  end




end
