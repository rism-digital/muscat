FactoryBot.define do
  factory :holding do
    lib_siglum "GB-xxx"
    wf_stage "published"
    institutions { []  }
  end
  
  factory :holding_fr, :parent => :holding do
    lib_siglum "F-Pn"
    wf_stage "published"
    marc_source <<STRING
=852  ##$aF-Pn$cMs 100$eBibliothèque nationale de France$x30001488
STRING
  end




end
